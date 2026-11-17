begin;

insert into auth.users (id, email) values
  ('dd000005-0000-4000-8000-000000000001', 'check-in-owner@example.invalid'),
  ('dd000005-0000-4000-8000-000000000002', 'check-in-member@example.invalid'),
  ('dd000005-0000-4000-8000-000000000003', 'check-in-outsider@example.invalid');

set local role authenticated;
select set_config('request.jwt.claim.sub', 'dd000005-0000-4000-8000-000000000001', true);
do $$ begin
  perform public.create_group('Check-in Group', 'dd000005-0000-4000-8000-000000000010');
  update public.profiles set display_name = 'Owner Display Name' where id = auth.uid();
end; $$;
select set_config('request.jwt.claim.sub', 'dd000005-0000-4000-8000-000000000003', true);
do $$ begin
  perform public.create_group('Separate Group', 'dd000005-0000-4000-8000-000000000011');
end; $$;
reset role;
insert into public.group_members (group_id, user_id, role) values
  ('dd000005-0000-4000-8000-000000000010', 'dd000005-0000-4000-8000-000000000002', 'member');

set local role anon;
do $$ begin
  begin
    perform * from public.check_ins;
    raise exception 'anonymous check-in reads must fail';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.submit_check_in('dd000005-0000-4000-8000-000000000010', 'dd000005-0000-4000-8000-000000000020', 'on_track', 'Denied');
    raise exception 'anonymous check-in submission must fail';
  exception when insufficient_privilege then null;
  end;
end; $$;
reset role;

set local role authenticated;
select set_config('request.jwt.claim.sub', 'dd000005-0000-4000-8000-000000000001', true);
do $$
declare
  posted public.check_ins;
  retried public.check_ins;
  invalid_note text;
  invalid_status text;
  statement text;
begin
  posted := public.submit_check_in('dd000005-0000-4000-8000-000000000010', 'dd000005-0000-4000-8000-000000000020', 'on_track', '  Read today  ');
  assert posted.note = 'Read today', 'update must be trimmed';
  assert posted.user_id = auth.uid(), 'author must be the authenticated caller';
  assert posted.author_name = 'Owner Display Name', 'name must come from caller profile';
  assert posted.created_at is not null, 'server must assign posting time';
  assert (select count(*) = 1 from public.check_ins), 'owner must read their post';
  retried := public.submit_check_in(posted.group_id, posted.id, posted.status, posted.note);
  assert retried.id = posted.id, 'replay must return the same check-in';
  assert (select count(*) = 1 from public.check_ins), 'replay must not duplicate check-ins';

  update public.profiles set display_name = 'Renamed Owner' where id = auth.uid();
  retried := public.submit_check_in(posted.group_id, posted.id, posted.status, posted.note);
  assert retried.author_name = 'Owner Display Name', 'historical names must remain stable on replay';
  begin
    perform public.submit_check_in(posted.group_id, posted.id, 'needs_support', posted.note);
    raise exception 'same ID with changed status must fail';
  exception when unique_violation then null;
  end;
  begin
    perform public.submit_check_in(posted.group_id, posted.id, posted.status, 'Changed');
    raise exception 'same ID with changed note must fail';
  exception when unique_violation then null;
  end;

  foreach invalid_note in array array[null, '', '   ', E'\t\n', repeat('x', 1001)] loop
    begin
      perform public.submit_check_in(posted.group_id, 'dd000005-0000-4000-8000-000000000021', 'on_track', invalid_note);
      raise exception 'invalid update must fail';
    exception when invalid_parameter_value then null;
    end;
  end loop;
  foreach invalid_status in array array[null, '', 'owner', 'invalid'] loop
    begin
      perform public.submit_check_in(posted.group_id, 'dd000005-0000-4000-8000-000000000021', invalid_status, 'Valid note');
      raise exception 'invalid status must fail';
    exception when invalid_parameter_value then null;
    end;
  end loop;
  begin
    perform public.submit_check_in(posted.group_id, null, 'on_track', 'Valid note');
    raise exception 'missing request ID must fail';
  exception when invalid_parameter_value then null;
  end;
  perform public.submit_check_in(posted.group_id, 'dd000005-0000-4000-8000-000000000022', 'needs_support', repeat('x', 1000));
  perform public.submit_check_in(posted.group_id, 'dd000005-0000-4000-8000-000000000023', 'on_track', repeat(chr(128512), 1000));

  foreach statement in array array[
    'insert into public.check_ins (group_id, user_id, author_name, status, note) values (''dd000005-0000-4000-8000-000000000010'', auth.uid(), ''Forged'', ''on_track'', ''Bypass'')',
    'update public.check_ins set note = ''Edited''',
    'update public.check_ins set author_name = ''Forged''',
    'update public.check_ins set user_id = auth.uid()',
    'update public.check_ins set group_id = ''dd000005-0000-4000-8000-000000000011''',
    'update public.check_ins set created_at = now()',
    'delete from public.check_ins'
  ] loop
    begin
      execute statement;
      raise exception 'direct client writes must fail: %', statement;
    exception when insufficient_privilege then null;
    end;
  end loop;
end;
$$;

select set_config('request.jwt.claim.sub', 'dd000005-0000-4000-8000-000000000002', true);
do $$
declare
  posted public.check_ins;
begin
  assert (select count(*) = 3 from public.check_ins), 'member must read the owner check-ins';
  posted := public.submit_check_in('dd000005-0000-4000-8000-000000000010', 'dd000005-0000-4000-8000-000000000024', 'needs_support', 'Need help staying consistent');
  assert posted.user_id = auth.uid(), 'member post must use member identity';
  assert posted.author_name = 'Group member', 'unset display name must use safe fallback';
  assert (select count(*) = 4 from public.check_ins), 'member must read shared history';
  assert (select count(*) = 1 from public.profiles), 'shared check-ins must not expose other profiles';
  begin
    perform public.submit_check_in(posted.group_id, 'dd000005-0000-4000-8000-000000000020', 'on_track', 'Read today');
    raise exception 'member cannot reuse another author request ID';
  exception when unique_violation then null;
  end;
  begin
    perform public.submit_check_in('dd000005-0000-4000-8000-000000000011', posted.id, posted.status, posted.note);
    raise exception 'member cannot post to another group';
  exception when insufficient_privilege then null;
  end;
end;
$$;

select set_config('request.jwt.claim.sub', 'dd000005-0000-4000-8000-000000000001', true);
do $$ begin
  assert exists (select 1 from public.check_ins where user_id = 'dd000005-0000-4000-8000-000000000002'),
    'owner must be able to read member check-ins';
end; $$;

select set_config('request.jwt.claim.sub', 'dd000005-0000-4000-8000-000000000003', true);
do $$ begin
  assert (select count(*) = 0 from public.check_ins), 'outsider cannot read another group history';
  assert not exists (select 1 from public.check_ins where id = 'dd000005-0000-4000-8000-000000000020'),
    'known check-in ID must not bypass RLS';
  begin
    perform public.submit_check_in('dd000005-0000-4000-8000-000000000010', 'dd000005-0000-4000-8000-000000000025', 'on_track', 'Denied');
    raise exception 'outsider cannot post';
  exception when insufficient_privilege then null;
  end;
  perform public.submit_check_in('dd000005-0000-4000-8000-000000000011', 'dd000005-0000-4000-8000-000000000026', 'on_track', 'Separate history');
  assert (select count(*) = 1 from public.check_ins), 'other group must have separate history';
end; $$;

select set_config('request.jwt.claim.sub', '', true);
do $$ begin
  assert (select count(*) = 0 from public.check_ins), 'missing identity sees no check-ins';
  begin
    perform public.submit_check_in('dd000005-0000-4000-8000-000000000010', 'dd000005-0000-4000-8000-000000000027', 'on_track', 'Denied');
    raise exception 'missing identity cannot post';
  exception when insufficient_privilege then null;
  end;
end; $$;
reset role;

delete from public.group_members where group_id = 'dd000005-0000-4000-8000-000000000010'
  and user_id = 'dd000005-0000-4000-8000-000000000002';
set local role authenticated;
select set_config('request.jwt.claim.sub', 'dd000005-0000-4000-8000-000000000002', true);
do $$ begin
  assert (select count(*) = 0 from public.check_ins), 'former member must lose history access';
  begin
    perform public.submit_check_in('dd000005-0000-4000-8000-000000000010', 'dd000005-0000-4000-8000-000000000024', 'needs_support', 'Need help staying consistent');
    raise exception 'former member cannot retrieve a post by replaying its ID';
  exception when insufficient_privilege then null;
  end;
end; $$;
reset role;

delete from auth.users where id = 'dd000005-0000-4000-8000-000000000002';
do $$ begin
  assert not exists (select 1 from public.check_ins where user_id = 'dd000005-0000-4000-8000-000000000002'),
    'administrative account deletion must remove authored check-ins';
end; $$;
delete from public.groups where id = 'dd000005-0000-4000-8000-000000000010';
do $$ begin
  assert not exists (select 1 from public.check_ins where group_id = 'dd000005-0000-4000-8000-000000000010'),
    'group deletion must remove its history';
end; $$;

rollback;
