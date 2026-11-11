begin;

insert into auth.users (id, email) values
  ('dd000003-0000-4000-8000-000000000001', 'invite-owner@example.invalid'),
  ('dd000003-0000-4000-8000-000000000002', 'invite-member@example.invalid'),
  ('dd000003-0000-4000-8000-000000000003', 'invite-outsider@example.invalid'),
  ('dd000003-0000-4000-8000-000000000004', 'invite-other-owner@example.invalid');

create temporary table invite_test_tokens (label text primary key, token text not null);
grant select, insert on invite_test_tokens to authenticated;

set local role anon;
do $$
declare
  statement text;
begin
  foreach statement in array array[
    'select * from public.group_invites',
    'select public.create_group_invite(''dd000003-0000-4000-8000-000000000010'')',
    'select public.revoke_group_invite(''dd000003-0000-4000-8000-000000000010'')',
    'select public.preview_group_invite(repeat(''a'', 64))',
    'select public.join_group_by_invite(repeat(''a'', 64))'
  ] loop
    begin
      execute statement;
      raise exception 'anonymous access must fail: %', statement;
    exception when insufficient_privilege then null;
    end;
  end loop;
end;
$$;
reset role;

set local role authenticated;
select set_config('request.jwt.claim.sub', '', true);
do $$
declare
  statement text;
begin
  foreach statement in array array[
    'select public.create_group_invite(''dd000003-0000-4000-8000-000000000010'')',
    'select public.revoke_group_invite(''dd000003-0000-4000-8000-000000000010'')',
    'select public.preview_group_invite(repeat(''a'', 64))',
    'select public.join_group_by_invite(repeat(''a'', 64))'
  ] loop
    begin
      execute statement;
      raise exception 'missing identity must fail: %', statement;
    exception when insufficient_privilege then null;
    end;
  end loop;
end;
$$;

select set_config('request.jwt.claim.sub', 'dd000003-0000-4000-8000-000000000004', true);
do $$ begin
  perform public.create_group('Other Private Group', 'dd000003-0000-4000-8000-000000000011');
end; $$;

select set_config('request.jwt.claim.sub', 'dd000003-0000-4000-8000-000000000001', true);
do $$
declare
  generated record;
  statement text;
begin
  perform public.create_group('Invited Group', 'dd000003-0000-4000-8000-000000000010');
  select * into generated from public.create_group_invite('dd000003-0000-4000-8000-000000000010');
  assert generated.token ~ '^[0-9a-f]{64}$', 'token must have the expected random format';
  assert generated.expires_at between now() + interval '6 days 23 hours' and now() + interval '7 days 1 hour',
    'invite must expire in seven days';
  insert into invite_test_tokens values ('original', generated.token);
  assert (select already_member from public.preview_group_invite(generated.token)), 'owner is already a member';
  perform public.join_group_by_invite(generated.token);
  assert (select role = 'owner' from public.group_members), 'joining cannot demote the owner';

  foreach statement in array array[
    'select public.create_group_invite(''dd000003-0000-4000-8000-000000000011'')',
    'select public.revoke_group_invite(''dd000003-0000-4000-8000-000000000011'')',
    'select * from public.group_invites',
    'insert into public.group_invites (group_id, token_hash, expires_at) values (''dd000003-0000-4000-8000-000000000011'', sha256(''bypass''::bytea), now())',
    'update public.group_invites set expires_at = now() + interval ''100 years''',
    'delete from public.group_invites'
  ] loop
    begin
      execute statement;
      raise exception 'unauthorized management or direct access must fail: %', statement;
    exception when insufficient_privilege then null;
    end;
  end loop;
end;
$$;
reset role;
do $$ begin
  assert exists (
    select 1 from public.group_invites
    where group_id = 'dd000003-0000-4000-8000-000000000010'
      and token_hash = sha256(convert_to((select token from invite_test_tokens where label = 'original'), 'UTF8'))
  ), 'only the token hash must be stored';
end; $$;

set local role authenticated;
select set_config('request.jwt.claim.sub', 'dd000003-0000-4000-8000-000000000002', true);
do $$
declare
  invitation_token text := (select token from invite_test_tokens where label = 'original');
  preview record;
  joined public.groups;
  invalid_token text;
begin
  assert (select count(*) = 0 from public.groups), 'recipient cannot list groups before joining';
  select * into preview from public.preview_group_invite(invitation_token);
  assert preview.group_name = 'Invited Group' and not preview.already_member, 'preview shows only the invited group';
  assert (select count(*) = 0 from public.group_members), 'preview must not join';
  assert (select count(*) = 0 from public.groups), 'preview must not grant group access';
  joined := public.join_group_by_invite(invitation_token);
  assert joined.id = preview.group_id, 'join must return the invited group';
  assert (select count(*) = 1 from public.groups), 'recipient can read only the joined group';
  assert (select role = 'member' from public.group_members), 'join must assign member';
  perform public.join_group_by_invite(invitation_token);
  assert (select count(*) = 1 from public.group_members), 'repeated join must not duplicate membership';
  assert (select already_member from public.preview_group_invite(invitation_token)), 'preview must detect existing membership';

  begin
    perform public.create_group_invite(joined.id);
    raise exception 'members cannot create invite links';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.revoke_group_invite(joined.id);
    raise exception 'members cannot revoke invite links';
  exception when insufficient_privilege then null;
  end;
  begin
    update public.group_members set role = 'owner' where user_id = auth.uid();
    raise exception 'members cannot promote themselves';
  exception when insufficient_privilege then null;
  end;

  foreach invalid_token in array array[null, '', 'invalid', repeat('f', 64), repeat('a', 65)] loop
    begin
      perform public.preview_group_invite(invalid_token);
      raise exception 'invalid preview must fail';
    exception when invalid_parameter_value then null;
    end;
    begin
      perform public.join_group_by_invite(invalid_token);
      raise exception 'invalid join must fail';
    exception when invalid_parameter_value then null;
    end;
  end loop;
end;
$$;

select set_config('request.jwt.claim.sub', 'dd000003-0000-4000-8000-000000000001', true);
insert into invite_test_tokens select 'replacement', token from public.create_group_invite('dd000003-0000-4000-8000-000000000010');
do $$ begin
  assert (select count(distinct token) = 2 from invite_test_tokens), 'replacing must generate a new token';
end; $$;

select set_config('request.jwt.claim.sub', 'dd000003-0000-4000-8000-000000000003', true);
do $$
declare
  old_token text := (select token from invite_test_tokens where label = 'original');
begin
  begin
    perform public.preview_group_invite(old_token);
    raise exception 'replaced link must not preview';
  exception when invalid_parameter_value then null;
  end;
  begin
    perform public.join_group_by_invite(old_token);
    raise exception 'replaced link must not join';
  exception when invalid_parameter_value then null;
  end;
  perform public.preview_group_invite((select token from invite_test_tokens where label = 'replacement'));
  assert (select count(*) = 0 from public.group_members), 'previewing replacement must not join';
  begin
    perform public.create_group_invite('dd000003-0000-4000-8000-000000000010');
    raise exception 'nonmembers cannot create invite links';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.revoke_group_invite('dd000003-0000-4000-8000-000000000010');
    raise exception 'nonmembers cannot revoke invite links';
  exception when insufficient_privilege then null;
  end;
end;
$$;

select set_config('request.jwt.claim.sub', 'dd000003-0000-4000-8000-000000000001', true);
do $$ begin
  perform public.revoke_group_invite('dd000003-0000-4000-8000-000000000010');
  perform public.revoke_group_invite('dd000003-0000-4000-8000-000000000010');
end; $$;

select set_config('request.jwt.claim.sub', 'dd000003-0000-4000-8000-000000000003', true);
do $$
declare
  revoked_token text := (select token from invite_test_tokens where label = 'replacement');
begin
  begin
    perform public.preview_group_invite(revoked_token);
    raise exception 'revoked link must not preview';
  exception when invalid_parameter_value then null;
  end;
  begin
    perform public.join_group_by_invite(revoked_token);
    raise exception 'revocation after preview must still prevent joining';
  exception when invalid_parameter_value then null;
  end;
  assert (select count(*) = 0 from public.group_members), 'failed join must not grant membership';
end;
$$;

select set_config('request.jwt.claim.sub', 'dd000003-0000-4000-8000-000000000002', true);
do $$ begin
  assert (select count(*) = 1 from public.groups), 'revocation must preserve existing members';
end; $$;

select set_config('request.jwt.claim.sub', 'dd000003-0000-4000-8000-000000000001', true);
insert into invite_test_tokens select 'shared', token from public.create_group_invite('dd000003-0000-4000-8000-000000000010');
select set_config('request.jwt.claim.sub', 'dd000003-0000-4000-8000-000000000003', true);
do $$ begin
  perform public.join_group_by_invite((select token from invite_test_tokens where label = 'shared'));
  assert (select role = 'member' from public.group_members), 'shared link must create a member';
end; $$;
select set_config('request.jwt.claim.sub', 'dd000003-0000-4000-8000-000000000004', true);
do $$ begin
  perform public.join_group_by_invite((select token from invite_test_tokens where label = 'shared'));
  assert (select count(*) = 2 from public.groups), 'shared link must allow multiple recipients';
  assert (select role = 'member' from public.group_members where group_id = 'dd000003-0000-4000-8000-000000000010'),
    'owning a different group must not grant ownership here';
end; $$;
reset role;

update public.group_invites set expires_at = clock_timestamp() - interval '1 second'
  where group_id = 'dd000003-0000-4000-8000-000000000010';
set local role authenticated;
select set_config('request.jwt.claim.sub', 'dd000003-0000-4000-8000-000000000002', true);
do $$
declare
  expired_token text := (select token from invite_test_tokens where label = 'shared');
begin
  begin
    perform public.preview_group_invite(expired_token);
    raise exception 'expired preview must fail';
  exception when invalid_parameter_value then null;
  end;
  begin
    perform public.join_group_by_invite(expired_token);
    raise exception 'expired join must fail';
  exception when invalid_parameter_value then null;
  end;
end;
$$;
reset role;

delete from public.groups where id = 'dd000003-0000-4000-8000-000000000010';
do $$ begin
  assert not exists (select 1 from public.group_invites where group_id = 'dd000003-0000-4000-8000-000000000010'),
    'group deletion must remove its invitation';
end; $$;

rollback;
