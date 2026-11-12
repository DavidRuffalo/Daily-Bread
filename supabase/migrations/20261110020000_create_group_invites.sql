begin;

create table public.group_invites (
  group_id uuid primary key references public.groups(id) on delete cascade,
  token_hash bytea not null unique check (octet_length(token_hash) = 32),
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);

alter table public.group_invites enable row level security;
revoke all on public.group_invites from public, anon, authenticated;

create function public.create_group_invite(target_group_id uuid)
returns table (token text, expires_at timestamptz)
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
  new_token text;
  expiration timestamptz := clock_timestamp() + interval '7 days';
begin
  if caller_id is null or not exists (
    select 1 from public.group_members
    where group_id = target_group_id and user_id = caller_id and role = 'owner'
  ) then
    raise exception 'Only the group owner can manage invite links.' using errcode = '42501';
  end if;

  new_token := replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', '');
  insert into public.group_invites (group_id, token_hash, expires_at)
    values (target_group_id, sha256(convert_to(new_token, 'UTF8')), expiration)
    on conflict (group_id) do update
      set token_hash = excluded.token_hash, expires_at = excluded.expires_at,
          created_at = clock_timestamp();

  return query select new_token, expiration;
end;
$$;

create function public.revoke_group_invite(target_group_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
begin
  if caller_id is null or not exists (
    select 1 from public.group_members
    where group_id = target_group_id and user_id = caller_id and role = 'owner'
  ) then
    raise exception 'Only the group owner can manage invite links.' using errcode = '42501';
  end if;

  delete from public.group_invites where group_id = target_group_id;
end;
$$;

create function public.preview_group_invite(invite_token text)
returns table (group_id uuid, group_name text, expires_at timestamptz, already_member boolean)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
begin
  if caller_id is null then
    raise exception 'Sign in to view this invitation.' using errcode = '42501';
  end if;
  if invite_token is null or invite_token !~ '^[0-9a-f]{64}$' then
    raise exception 'This invite link is invalid, expired, or revoked.' using errcode = '22023';
  end if;

  return query
    select invite.group_id, groups.name, invite.expires_at, exists (
      select 1 from public.group_members members
      where members.group_id = invite.group_id and members.user_id = caller_id
    )
    from public.group_invites invite
    join public.groups groups on groups.id = invite.group_id
    where invite.token_hash = sha256(convert_to(invite_token, 'UTF8'))
      and invite.expires_at > statement_timestamp();

  if not found then
    raise exception 'This invite link is invalid, expired, or revoked.' using errcode = '22023';
  end if;
end;
$$;

create function public.join_group_by_invite(invite_token text)
returns public.groups
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
  invitation public.group_invites;
  joined_group public.groups;
begin
  if caller_id is null then
    raise exception 'Sign in to join a group.' using errcode = '42501';
  end if;
  if invite_token is null or invite_token !~ '^[0-9a-f]{64}$' then
    raise exception 'This invite link is invalid, expired, or revoked.' using errcode = '22023';
  end if;

  select * into invitation from public.group_invites
    where token_hash = sha256(convert_to(invite_token, 'UTF8'))
    for update;
  if not found or invitation.expires_at <= clock_timestamp() then
    raise exception 'This invite link is invalid, expired, or revoked.' using errcode = '22023';
  end if;

  insert into public.group_members (group_id, user_id, role)
    values (invitation.group_id, caller_id, 'member')
    on conflict (group_id, user_id) do nothing;

  select * into joined_group from public.groups where id = invitation.group_id;
  return joined_group;
end;
$$;

revoke all on function public.create_group_invite(uuid) from public, anon, authenticated;
revoke all on function public.revoke_group_invite(uuid) from public, anon, authenticated;
revoke all on function public.preview_group_invite(text) from public, anon, authenticated;
revoke all on function public.join_group_by_invite(text) from public, anon, authenticated;
grant execute on function public.create_group_invite(uuid) to authenticated;
grant execute on function public.revoke_group_invite(uuid) to authenticated;
grant execute on function public.preview_group_invite(text) to authenticated;
grant execute on function public.join_group_by_invite(text) to authenticated;

commit;
