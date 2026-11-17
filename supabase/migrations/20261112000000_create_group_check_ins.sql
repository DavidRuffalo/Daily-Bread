begin;

create table public.check_ins (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  author_name text not null check (char_length(author_name) between 1 and 80),
  status text not null check (status in ('on_track', 'needs_support')),
  note text not null,
  created_at timestamptz not null default now(),
  constraint check_ins_note_valid check (
    note = btrim(note) and char_length(note) between 1 and 1000
      and note ~ '[^[:space:]]'
  )
);

create index check_ins_group_recent_idx on public.check_ins (group_id, created_at desc, id desc);
create index check_ins_user_id_idx on public.check_ins (user_id);

alter table public.check_ins enable row level security;
revoke all on public.check_ins from public, anon, authenticated;
grant select on public.check_ins to authenticated;

create policy check_ins_select_joined on public.check_ins
  for select to authenticated using (
    exists (
      select 1 from public.group_members
      where group_id = check_ins.group_id and user_id = (select auth.uid())
    )
  );

create function public.submit_check_in(
  target_group_id uuid,
  check_in_id uuid,
  check_in_status text,
  check_in_note text
)
returns public.check_ins
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
  normalized_note text := btrim(check_in_note);
  display_name text;
  result public.check_ins;
begin
  if caller_id is null then
    raise exception 'Sign in to post a check-in.' using errcode = '42501';
  end if;

  perform 1 from public.group_members
    where group_id = target_group_id and user_id = caller_id
    for key share;
  if not found then
    raise exception 'You must belong to this group to post a check-in.' using errcode = '42501';
  end if;
  if check_in_id is null or check_in_status is null
      or check_in_status not in ('on_track', 'needs_support')
      or normalized_note is null or char_length(normalized_note) not between 1 and 1000
      or normalized_note !~ '[^[:space:]]' then
    raise exception 'Choose a status and write an update between 1 and 1,000 characters.' using errcode = '22023';
  end if;

  select coalesce(profiles.display_name, 'Group member') into display_name
    from public.profiles where id = caller_id;
  display_name := coalesce(display_name, 'Group member');

  insert into public.check_ins (id, group_id, user_id, author_name, status, note)
    values (check_in_id, target_group_id, caller_id, display_name, check_in_status, normalized_note)
    on conflict (id) do nothing
    returning * into result;

  if not found then
    select * into result from public.check_ins
      where id = check_in_id and group_id = target_group_id and user_id = caller_id
        and status = check_in_status and note = normalized_note;
    if not found then
      raise exception 'Unable to post this check-in.' using errcode = '23505';
    end if;
  end if;

  return result;
end;
$$;

revoke all on function public.submit_check_in(uuid, uuid, text, text) from public, anon, authenticated;
grant execute on function public.submit_check_in(uuid, uuid, text, text) to authenticated;

commit;
