begin;

create table public.groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint groups_name_valid check (
    name = btrim(name) and char_length(name) between 1 and 80
  )
);

create index groups_created_by_idx on public.groups (created_by);

create table public.group_members (
  group_id uuid not null references public.groups(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('owner', 'member')),
  joined_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

create index group_members_user_id_idx on public.group_members (user_id, group_id);
create unique index group_members_one_owner_idx on public.group_members (group_id)
  where role = 'owner';

alter table public.groups enable row level security;
alter table public.group_members enable row level security;

revoke all on public.groups, public.group_members from public, anon, authenticated;
grant select on public.groups, public.group_members to authenticated;

-- Members can read their own membership, not a group-wide roster yet.
-- This policy does not query groups, avoiding a recursive RLS dependency.
create policy group_members_select_own on public.group_members
  for select to authenticated using (user_id = (select auth.uid()));

create policy groups_select_joined on public.groups
  for select to authenticated using (
    exists (
      select 1 from public.group_members
      where group_id = groups.id and user_id = (select auth.uid())
    )
  );

-- A single transaction assigns ownership from the authenticated identity.
-- There are no browser grants for direct group or membership writes.
create function public.create_group(group_name text, group_id uuid)
returns public.groups
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
  normalized_name text := btrim(group_name);
  result public.groups;
begin
  if caller_id is null then
    raise exception 'Sign in to create a group.' using errcode = '42501';
  end if;
  if normalized_name is null or char_length(normalized_name) not between 1 and 80 then
    raise exception 'Use a group name between 1 and 80 characters.' using errcode = '22023';
  end if;
  if group_id is null then
    raise exception 'A group ID is required.' using errcode = '22023';
  end if;

  insert into public.groups (id, name, created_by)
    values (group_id, normalized_name, caller_id)
    on conflict (id) do nothing
    returning * into result;

  if found then
    insert into public.group_members (group_id, user_id, role)
      values (result.id, caller_id, 'owner');
  else
    -- Retrying a request whose response was lost must not create a duplicate.
    select * into result from public.groups
      where id = group_id and created_by = caller_id and name = normalized_name;
    if not found then
      raise exception 'Unable to create this group.' using errcode = '23505';
    end if;
  end if;

  return result;
end;
$$;

revoke all on function public.create_group(text, uuid) from public, anon, authenticated;
grant execute on function public.create_group(text, uuid) to authenticated;

commit;
