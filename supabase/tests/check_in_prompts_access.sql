begin;
insert into auth.users (id, email) values
  ('dd000007-0000-4000-8000-000000000001', 'prompt-owner@example.invalid'),
  ('dd000007-0000-4000-8000-000000000002', 'prompt-member@example.invalid'),
  ('dd000007-0000-4000-8000-000000000003', 'prompt-outsider@example.invalid');
set local role authenticated;
select set_config('request.jwt.claim.sub', 'dd000007-0000-4000-8000-000000000001', true);
select public.create_group('Prompt Group', 'dd000007-0000-4000-8000-000000000010');
reset role;
insert into public.group_members (group_id, user_id, role) values
  ('dd000007-0000-4000-8000-000000000010', 'dd000007-0000-4000-8000-000000000002', 'member');

set local role anon;
do $$ begin
  begin
    perform public.set_check_in_prompt('dd000007-0000-4000-8000-000000000010', 'Denied');
    raise exception 'anonymous prompt edits must fail';
  exception when insufficient_privilege then null; end;
end; $$;
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub', 'dd000007-0000-4000-8000-000000000001', true);
do $$
declare
  posted public.check_ins;
  retried public.check_ins;
  invalid text;
begin
  assert (select check_in_prompt = 'Share how you are doing with your goals.' from public.groups), 'default question';
  posted := public.submit_check_in('dd000007-0000-4000-8000-000000000010', 'dd000007-0000-4000-8000-000000000020', 'on_track', 'Original answer');
  assert posted.prompt = 'Share how you are doing with your goals.', 'legacy calls snapshot default';
  assert public.set_check_in_prompt(posted.group_id, '  What did you read today?  ') = 'What did you read today?', 'trim question';
  assert (select prompt = posted.prompt from public.check_ins where id = posted.id), 'editing must preserve old posts';
  retried := public.submit_check_in(posted.group_id, posted.id, posted.status, posted.note, posted.prompt);
  assert retried = posted, 'replay survives question changes';
  begin
    perform public.submit_check_in(posted.group_id, posted.id, posted.status, posted.note, 'Forged question');
    raise exception 'changed question cannot reuse request';
  exception when unique_violation then null; end;
  begin
    perform public.submit_check_in(posted.group_id, 'dd000007-0000-4000-8000-000000000021', 'on_track', 'Stale answer', posted.prompt);
    raise exception 'stale question must not insert';
  exception when no_data_found then null; end;
  assert (select count(*) = 1 from public.check_ins), 'stale submission made no post';
  foreach invalid in array array[null, '', '   ', E'\t\n', repeat('x', 301)] loop
    begin
      perform public.set_check_in_prompt(posted.group_id, invalid);
      raise exception 'invalid question must fail';
    exception when invalid_parameter_value then null; end;
  end loop;
  perform public.set_check_in_prompt(posted.group_id, repeat(chr(128512), 300));
  perform public.set_check_in_prompt(posted.group_id, 'What did you read today?');
  begin
    update public.groups set check_in_prompt = 'Bypass';
    raise exception 'direct question edits must fail';
  exception when insufficient_privilege then null; end;
  begin
    update public.check_ins set prompt = 'Forged';
    raise exception 'direct snapshot edits must fail';
  exception when insufficient_privilege then null; end;
end; $$;

select set_config('request.jwt.claim.sub', 'dd000007-0000-4000-8000-000000000002', true);
do $$ declare posted public.check_ins; begin
  assert (select check_in_prompt = 'What did you read today?' from public.groups), 'members read current question';
  begin
    perform public.set_check_in_prompt('dd000007-0000-4000-8000-000000000010', 'Denied');
    raise exception 'member question edits must fail';
  exception when insufficient_privilege then null; end;
  posted := public.submit_check_in('dd000007-0000-4000-8000-000000000010', 'dd000007-0000-4000-8000-000000000022', 'on_track', 'Read John', 'What did you read today?');
  assert posted.prompt = 'What did you read today?', 'members snapshot current question';
end; $$;

select set_config('request.jwt.claim.sub', 'dd000007-0000-4000-8000-000000000003', true);
do $$ begin
  assert (select count(*) = 0 from public.groups), 'outsider cannot read questions';
  assert (select count(*) = 0 from public.check_ins), 'outsider cannot read snapshots';
  begin
    perform public.set_check_in_prompt('dd000007-0000-4000-8000-000000000010', 'Denied');
    raise exception 'outsider question edits must fail';
  exception when insufficient_privilege then null; end;
end; $$;
select set_config('request.jwt.claim.sub', '', true);
do $$ begin
  begin
    perform public.set_check_in_prompt('dd000007-0000-4000-8000-000000000010', 'Denied');
    raise exception 'missing identity question edits must fail';
  exception when insufficient_privilege then null; end;
end; $$;
reset role;
rollback;
