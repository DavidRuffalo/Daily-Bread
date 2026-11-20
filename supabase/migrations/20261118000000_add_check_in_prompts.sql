begin;

alter table public.groups add column check_in_prompt text not null
  default 'Share how you are doing with your goals.'
  check (check_in_prompt = btrim(check_in_prompt)
    and char_length(check_in_prompt) between 1 and 300 and check_in_prompt ~ '[^[:space:]]');

-- Existing posts answered the original fixed question.
alter table public.check_ins add column prompt text not null
  default 'Share how you are doing with your goals.'
  check (char_length(prompt) between 1 and 300 and prompt ~ '[^[:space:]]');

create function public.set_check_in_prompt(target_group_id uuid, new_prompt text)
returns text
language plpgsql security definer set search_path = ''
as $$
declare
  normalized_prompt text := btrim(new_prompt);
begin
  if auth.uid() is null then
    raise exception 'Sign in to change the prompt.' using errcode = '42501';
  end if;
  perform 1 from public.group_members
    where group_id = target_group_id and user_id = auth.uid() and role = 'owner'
    for key share;
  if not found then
    raise exception 'Only the group owner can change the prompt.' using errcode = '42501';
  end if;
  if normalized_prompt is null or char_length(normalized_prompt) not between 1 and 300
      or normalized_prompt !~ '[^[:space:]]' then
    raise exception 'Write a question between 1 and 300 characters.' using errcode = '22023';
  end if;
  update public.groups set check_in_prompt = normalized_prompt where id = target_group_id;
  return normalized_prompt;
end;
$$;
revoke all on function public.set_check_in_prompt(uuid, text) from public, anon, authenticated;
grant execute on function public.set_check_in_prompt(uuid, text) to authenticated;

-- Keep four-argument calls working during rollout. New clients send the question
-- they actually displayed, so a concurrent owner edit cannot relabel an answer.
drop function public.submit_check_in(uuid, uuid, text, text);
create function public.submit_check_in(
  target_group_id uuid, check_in_id uuid, check_in_status text, check_in_note text,
  expected_prompt text default null
)
returns public.check_ins
language plpgsql security definer set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
  normalized_note text := btrim(check_in_note);
  display_name text;
  current_prompt text;
  result public.check_ins;
begin
  if caller_id is null then
    raise exception 'Sign in to post a check-in.' using errcode = '42501';
  end if;
  perform 1 from public.group_members
    where group_id = target_group_id and user_id = caller_id for key share;
  if not found then
    raise exception 'You must belong to this group to post a check-in.' using errcode = '42501';
  end if;
  if check_in_id is null or check_in_status is null
      or check_in_status not in ('on_track', 'needs_support')
      or normalized_note is null or char_length(normalized_note) not between 1 and 1000
      or normalized_note !~ '[^[:space:]]' then
    raise exception 'Choose a status and write an update between 1 and 1,000 characters.' using errcode = '22023';
  end if;

  -- Return committed retries even if the owner has since changed the question.
  select * into result from public.check_ins where id = check_in_id;
  if found then
    if result.group_id = target_group_id and result.user_id = caller_id
        and result.status = check_in_status and result.note = normalized_note
        and (expected_prompt is null or result.prompt = expected_prompt) then
      return result;
    end if;
    raise exception 'Unable to post this check-in.' using errcode = '23505';
  end if;

  select check_in_prompt into current_prompt from public.groups
    where id = target_group_id for share;
  if expected_prompt is not null and expected_prompt <> current_prompt then
    raise exception 'The check-in question has changed. Refresh and review it before posting.' using errcode = 'P0002';
  end if;
  select coalesce(profiles.display_name, 'Group member') into display_name
    from public.profiles where id = caller_id;
  display_name := coalesce(display_name, 'Group member');

  insert into public.check_ins (id, group_id, user_id, author_name, status, note, prompt)
    values (check_in_id, target_group_id, caller_id, display_name, check_in_status, normalized_note, current_prompt)
    on conflict (id) do nothing returning * into result;
  if not found then
    select * into result from public.check_ins
      where id = check_in_id and group_id = target_group_id and user_id = caller_id
        and status = check_in_status and note = normalized_note
        and (expected_prompt is null or prompt = expected_prompt);
    if not found then
      raise exception 'Unable to post this check-in.' using errcode = '23505';
    end if;
  end if;
  return result;
end;
$$;
revoke all on function public.submit_check_in(uuid, uuid, text, text, text) from public, anon, authenticated;
grant execute on function public.submit_check_in(uuid, uuid, text, text, text) to authenticated;

commit;
