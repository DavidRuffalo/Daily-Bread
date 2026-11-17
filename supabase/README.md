# Database changes

SQL migrations are kept in `migrations/` so database changes can be reviewed
with the feature that uses them. Adding a migration file does not apply it
to the hosted Supabase project.

## Profiles

`migrations/20261110000000_create_profiles.sql` adds:

| Column | Purpose |
| --- | --- |
| `id` | Same UUID as the account in `auth.users`; one profile per account. |
| `display_name` | Optional name, trimmed and between 1 and 80 characters when set. |
| `created_at` | Time the profile row was created. |

Existing accounts get a profile with an unset name. A database trigger
creates a profile for each new account. Deleting an account also deletes
its profile.

Signed-in users can read their own profile and update only `display_name`.
Row-level security restricts which row they can access; column grants
protect `id` and `created_at`. Browser clients cannot insert or delete
profiles, and signed-out clients have no profile access.

## Groups

`migrations/20261110010000_create_groups.sql` adds `groups`, `group_members`,
and the `create_group(group_name text, group_id uuid)` RPC. Group names are
trimmed and must contain 1 to 80 characters. Names are not unique. The RPC
assigns the authenticated caller as creator and owner in one transaction.
The caller supplies a UUID so retrying the same ID and name returns the
original group; an ID belonging to another creator cannot be reused or read.

Both tables have RLS and only SELECT grants for authenticated clients.
Users can read groups they belong to and only their own membership rows.
The membership policy does not query groups, avoiding recursive policies.
There are no direct client writes, self-joining, or role changes. The RPC
uses a fixed empty search path, qualified table names, an explicit identity
check, and EXECUTE granted only to authenticated users. Only trusted server
operations may add other members until invite redemption is implemented.

Deleting an account administratively removes its memberships and groups it
created; deleting a group removes its memberships. No account/group deletion
UI or ownership transfer is included. The unique owner index permits at most
one owner per group; the create RPC ensures every newly created group has one.

Run the rolled-back role/access checks with:

```powershell
npx.cmd supabase db query --remote=<project-ref> --file supabase/tests/groups_access.sql --yes
```

These fixtures also force owner insertion to fail to check atomic rollback,
and test retrying an ID without duplicating the group. As with profile tests,
these checks impersonate database roles; they do not test browser sessions
or the HTTP API. See [the groups PR plan](../docs/group-creation.md) for the
browser checklist and feature boundaries.

On November 10, 2026, both migrations and both access-test files passed in
isolated PGlite. The groups migration was then applied to the configured
hosted `daily-bread` project and recorded in migration history. Hosted
groups access tests passed and rolled back all fixture changes. Follow-up
read-only verification confirmed RLS on both tables, authenticated-only
creation, denied direct membership inserts, and zero fixture users or group
rows remaining before browser testing. David subsequently verified group
creation and the Owner label, persistence after reload, group detail/back
navigation, and separate groups across two accounts. Offline creation
retained the draft and allowed a successful retry with one group listed;
offline group loading showed feedback and recovered through Retry loading
groups without a page reload. An 81-character name was rejected, and
spaces-only input kept Create group disabled. The planned local browser
checks are complete; the deployed groups UI is still unverified.

## Apply and verify

After reviewing the migration:

1. Authenticate the Supabase CLI with `npx.cmd supabase login`.
2. From the repository root, apply migrations to the intended project with
   `npx.cmd supabase migration up --remote=<project-ref> --yes`.
   This also records the migration in Supabase's migration history. It uses
   a transaction so an error rolls back the change. If `profiles` already
   exists, inspect the existing schema before proceeding.
3. Run `tests/profiles_access.sql` in the development project with
   `npx.cmd supabase db query --remote=<project-ref> --file supabase/tests/profiles_access.sql --yes`.
   It creates synthetic fixture users, checks the trigger and access rules,
   and rolls back all test changes. If it errors, issue `rollback;` before
   running more SQL in that session.
4. Check that existing accounts have profile rows. Test a fresh signup to
   confirm that Supabase Auth still works and creates the new profile.

Use `npm`/`npx` without `.cmd` on macOS or Linux. The placeholder project ref
must match the app's configured Supabase project. The CLI login is separate
from signing in to the app, and no secret credentials belong in Git.

The SQL access test impersonates database roles and user IDs inside a
trusted database session. It does not test browser authentication or the
Supabase HTTP API. Test access from two signed-in browser accounts when the
profile form is connected.

On November 10, 2026, the migration, existing-account backfill, and access
checks passed in an isolated PGlite PostgreSQL engine with a minimal Auth
schema. The migration was then applied through the Supabase CLI to the
hosted `daily-bread` project matched to the app configuration, and the
migration-history record was verified. Hosted SQL access checks passed,
including profile creation for fixture accounts, and their transaction
rolled back successfully. A read-only check confirmed two real accounts,
two profiles, no missing profiles, enabled RLS, the intended grants, the
signup trigger, and no remaining fixture accounts. David verified browser
profile loading and saving, persistence after reload, clearing the name, and
read/update isolation across two signed-in accounts. An offline save retained
the draft and previous saved heading, displayed feedback, and allowed a
successful retry after reconnecting; the new name persisted after reload.
David then verified that a fresh signup through Supabase Auth could load its
empty profile form. A final hosted read-only check confirmed three accounts,
three profiles, no missing profiles, and the migration-history record.
David also verified that a blocked profile-load request displayed an error
and retry button, and that removing the block and retrying restored the
saved profile without refreshing. The deployed profile UI has not yet
been verified.

References: [Supabase profiles](https://supabase.com/docs/guides/auth/managing-user-data),
[row-level security](https://supabase.com/docs/guides/database/postgres/row-level-security),
[column permissions](https://supabase.com/docs/guides/database/postgres/column-level-security),
and [database functions](https://supabase.com/docs/guides/database/functions).
