-- Run as postgres after both migrations. All fixtures are rolled back.
begin;

insert into auth.users (id, email) values
  ('dd000002-0000-4000-8000-000000000001', 'group-owner@example.invalid'),
  ('dd000002-0000-4000-8000-000000000002', 'group-member@example.invalid'),
  ('dd000002-0000-4000-8000-000000000003', 'group-outsider@example.invalid');

set local role anon;
do $$
begin
  begin
    perform * from public.groups;
    raise exception 'anonymous group reads must fail';
  exception when insufficient_privilege then null;
  end;
  begin
    perform * from public.group_members;
    raise exception 'anonymous membership reads must fail';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.create_group('Denied', 'dd000002-0000-4000-8000-000000000010');
    raise exception 'anonymous group creation must fail';
  exception when insufficient_privilege then null;
  end;
end;
$$;
reset role;

set local role authenticated;
select set_config('request.jwt.claim.sub', 'dd000002-0000-4000-8000-000000000001', true);
do $$
declare
  created public.groups;
  retried public.groups;
  invalid_name text;
  statement text;
begin
  created := public.create_group('  Group Test  ', 'dd000002-0000-4000-8000-000000000010');
  assert created.name = 'Group Test', 'group name must be trimmed';
  assert created.created_by = auth.uid(), 'creator must come from auth identity';
  assert (select count(*) = 1 from public.groups), 'creator can read new group';
  assert (
    select count(*) = 1 from public.group_members
    where group_id = created.id and user_id = auth.uid() and role = 'owner'
  ), 'creator must receive owner membership';

  retried := public.create_group('Group Test', created.id);
  assert retried.id = created.id, 'retries must return the same group';
  assert (select count(*) = 1 from public.groups), 'retries must not duplicate groups';
  assert (select count(*) = 1 from public.group_members), 'retries must not duplicate ownership';

  begin
    perform public.create_group('Different name', created.id);
    raise exception 'same ID with changed input must fail';
  exception when unique_violation then null;
  end;

  foreach invalid_name in array array[null, '', '   ', repeat('x', 81)] loop
    begin
      perform public.create_group(invalid_name, 'dd000002-0000-4000-8000-000000000011');
      raise exception 'invalid group name must fail';
    exception when invalid_parameter_value then null;
    end;
  end loop;
  begin
    perform public.create_group('Missing ID', null);
    raise exception 'missing group ID must fail';
  exception when invalid_parameter_value then null;
  end;
  perform public.create_group(repeat('x', 80), 'dd000002-0000-4000-8000-000000000012');

  -- Neither owners nor members may bypass the RPC or assign roles directly.
  foreach statement in array array[
    'insert into public.groups (name, created_by) values (''Bypass'', auth.uid())',
    'update public.groups set name = ''Bypass''',
    'update public.groups set created_by = auth.uid()',
    'delete from public.groups',
    'insert into public.group_members (group_id, user_id, role) values (''dd000002-0000-4000-8000-000000000010'', auth.uid(), ''owner'')',
    'update public.group_members set role = ''owner''',
    'delete from public.group_members'
  ] loop
    begin
      execute statement;
      raise exception 'direct write must fail: %', statement;
    exception when insufficient_privilege then null;
    end;
  end loop;
end;
$$;
reset role;

-- Add a member as a trusted database fixture; invites are a later feature.
insert into public.group_members (group_id, user_id, role) values
  ('dd000002-0000-4000-8000-000000000010', 'dd000002-0000-4000-8000-000000000002', 'member');

set local role authenticated;
select set_config('request.jwt.claim.sub', 'dd000002-0000-4000-8000-000000000002', true);
do $$
begin
  assert (select count(*) = 1 from public.groups), 'member must see only joined group';
  assert (select name = 'Group Test' from public.groups), 'member must see correct group';
  assert (select count(*) = 1 from public.group_members), 'member sees only own membership';
  assert (select role = 'member' from public.group_members), 'member role must stay member';
  begin
    update public.group_members set role = 'owner' where user_id = auth.uid();
    raise exception 'member cannot promote themselves';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.create_group('Group Test', 'dd000002-0000-4000-8000-000000000010');
    raise exception 'member cannot claim existing group';
  exception when unique_violation then null;
  end;
end;
$$;

select set_config('request.jwt.claim.sub', 'dd000002-0000-4000-8000-000000000003', true);
do $$
begin
  assert (select count(*) = 0 from public.groups), 'outsider cannot read groups';
  assert (select count(*) = 0 from public.group_members), 'outsider cannot read memberships';
  assert not exists (
    select 1 from public.groups where id = 'dd000002-0000-4000-8000-000000000010'
  ), 'knowing a group ID must not bypass RLS';
  begin
    perform public.create_group('Group Test', 'dd000002-0000-4000-8000-000000000010');
    raise exception 'outsider cannot claim or retrieve another group through RPC';
  exception when unique_violation then null;
  end;
  begin
    insert into public.group_members (group_id, user_id, role)
      values ('dd000002-0000-4000-8000-000000000010', auth.uid(), 'member');
    raise exception 'outsider cannot join directly';
  exception when insufficient_privilege then null;
  end;
  perform public.create_group('Outsider Own Group', 'dd000002-0000-4000-8000-000000000013');
  assert (select count(*) = 1 from public.groups), 'second creator must see only their group';
end;
$$;

select set_config('request.jwt.claim.sub', '', true);
do $$
begin
  assert (select count(*) = 0 from public.groups), 'missing identity sees no groups';
  assert (select count(*) = 0 from public.group_members), 'missing identity sees no memberships';
  begin
    perform public.create_group('Denied', 'dd000002-0000-4000-8000-000000000014');
    raise exception 'missing identity cannot create a group';
  exception when insufficient_privilege then null;
  end;
end;
$$;
reset role;

-- Force the second insert to fail and ensure the group insert also rolls back.
alter table public.group_members add constraint test_owner_failure
  check (group_id <> 'dd000002-0000-4000-8000-000000000015'::uuid);
set local role authenticated;
select set_config('request.jwt.claim.sub', 'dd000002-0000-4000-8000-000000000001', true);
do $$
begin
  begin
    perform public.create_group('Atomic Test', 'dd000002-0000-4000-8000-000000000015');
    raise exception 'forced membership failure must propagate';
  exception when check_violation then null;
  end;
end;
$$;
reset role;
do $$
begin
  assert not exists (
    select 1 from public.groups where id = 'dd000002-0000-4000-8000-000000000015'
  ), 'failed owner creation must not leave an orphan group';
end;
$$;
alter table public.group_members drop constraint test_owner_failure;

-- Account deletion is administrative only: members leave, owners take groups with them.
delete from auth.users where id = 'dd000002-0000-4000-8000-000000000002';
do $$
begin
  assert exists (select 1 from public.groups where id = 'dd000002-0000-4000-8000-000000000010'),
    'deleting a member must preserve the group';
end;
$$;
delete from auth.users where id = 'dd000002-0000-4000-8000-000000000001';
do $$
begin
  assert not exists (select 1 from public.groups where created_by = 'dd000002-0000-4000-8000-000000000001'),
    'deleting the creator must remove owned groups';
  assert not exists (select 1 from public.group_members where group_id = 'dd000002-0000-4000-8000-000000000010'),
    'deleting the group must remove memberships';
end;
$$;

rollback;
