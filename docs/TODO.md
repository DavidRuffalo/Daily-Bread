# TODO

Progress below includes app commit `df2c3e8`, pushed on `feature/app-setup`; PR/merge status has not been verified. See [app-setup.md](app-setup.md) for the current PR goal, completed checks, and wrap-up work.

## Setup (shared)

- [x] Create the React + Vite app
- [x] Create the Supabase project
- [x] Put Supabase keys in `.env.local` (gitignored)
- [x] Add a README with run steps

## Track A: Auth

- [x] Set up the Supabase client
- [ ] Sign-up page
- [x] Log-in page
- [x] Log out
- [x] Session / auth state handling
- [ ] Protected-route wrapper
- [ ] `profiles` table linked to `auth.users`

## Track B: Groups + Dashboard

- [ ] `groups` table
- [ ] `group_members` table (creator = owner)
- [ ] Basic RLS policies for groups and members
- [ ] Create-group form
- [ ] Dashboard listing my groups
- [ ] Group detail page (stub)

## Next Up

- [ ] Settle the [open decisions](daily-bread.md#open-decisions) before starting the next feature
