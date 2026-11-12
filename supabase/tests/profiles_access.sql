-- Run against a development database after the profiles migration, as postgres.
-- Fixture users and all profile edits are rolled back. No real emails are used.
begin;

insert into auth.users (id, email) values
  ('dd000001-0000-4000-8000-000000000001', 'profile-owner@example.invalid'),
  ('dd000001-0000-4000-8000-000000000002', 'profile-other@example.invalid');

do $$
begin
  assert (
    select count(*) = 2 from public.profiles
    where id in (
      'dd000001-0000-4000-8000-000000000001',
      'dd000001-0000-4000-8000-000000000002'
    )
  ), 'signup trigger must create both profiles';
end;
$$;

set local role anon;
do $$
begin
  begin
    perform id from public.profiles;
    raise exception 'anonymous profile reads must be denied';
  exception when insufficient_privilege then null;
  end;
end;
$$;
reset role;

set local role authenticated;
select set_config('request.jwt.claim.sub', 'dd000001-0000-4000-8000-000000000001', true);

do $$
declare
  affected integer;
begin
  assert (select count(*) = 1 from public.profiles), 'owner must see only one profile';
  assert (
    select id = 'dd000001-0000-4000-8000-000000000001'::uuid from public.profiles
  ), 'owner must see their own profile';

  update public.profiles set display_name = 'Profile Test'
  where id = 'dd000001-0000-4000-8000-000000000001';
  get diagnostics affected = row_count;
  assert affected = 1, 'owner must be able to update their display name';
  assert (select display_name = 'Profile Test' from public.profiles), 'name must persist';

  update public.profiles set display_name = 'Unauthorized'
  where id = 'dd000001-0000-4000-8000-000000000002';
  get diagnostics affected = row_count;
  assert affected = 0, 'owner must not update another profile';

  begin
    update public.profiles set id = id;
    raise exception 'profile ownership changes must be denied';
  exception when insufficient_privilege then null;
  end;

  begin
    update public.profiles set created_at = now();
    raise exception 'profile creation time changes must be denied';
  exception when insufficient_privilege then null;
  end;

  begin
    insert into public.profiles (id) values ('dd000001-0000-4000-8000-000000000001');
    raise exception 'browser profile inserts must be denied';
  exception when insufficient_privilege then null;
  end;

  begin
    delete from public.profiles;
    raise exception 'browser profile deletes must be denied';
  exception when insufficient_privilege then null;
  end;

  begin
    update public.profiles set display_name = '';
    raise exception 'empty display names must be rejected';
  exception when check_violation then null;
  end;

  begin
    update public.profiles set display_name = ' Untrimmed ';
    raise exception 'untrimmed display names must be rejected';
  exception when check_violation then null;
  end;

  begin
    update public.profiles set display_name = repeat('x', 81);
    raise exception 'overlong display names must be rejected';
  exception when check_violation then null;
  end;

  update public.profiles set display_name = null;
  assert (select display_name is null from public.profiles), 'an unset name must be allowed';
end;
$$;

select set_config('request.jwt.claim.sub', 'dd000001-0000-4000-8000-000000000002', true);
do $$
begin
  assert (select count(*) = 1 from public.profiles), 'second user must see only one profile';
  assert (
    select id = 'dd000001-0000-4000-8000-000000000002'::uuid from public.profiles
  ), 'second user must see their own profile';
  assert (select display_name is null from public.profiles), 'other profile must remain unchanged';
end;
$$;

select set_config('request.jwt.claim.sub', '', true);
do $$
begin
  assert (select count(*) = 0 from public.profiles), 'missing identity must see no profiles';
end;
$$;
reset role;

delete from auth.users where id = 'dd000001-0000-4000-8000-000000000002';
do $$
begin
  assert not exists (
    select 1 from public.profiles where id = 'dd000001-0000-4000-8000-000000000002'
  ), 'deleting an account must delete its profile';
end;
$$;

rollback;
