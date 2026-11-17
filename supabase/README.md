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
and [column permissions](https://supabase.com/docs/guides/database/postgres/column-level-security).
