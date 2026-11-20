# TODO

PRs #1–#9 were verified merged on November 17, 2026. Pages successfully
deployed `main` at `17278f4`. The original [app-setup.md](app-setup.md) is
a historical setup handoff; feature notes record later validation results.

## Setup (shared)

- [x] Create the React + Vite app
- [x] Create the Supabase project
- [x] Put Supabase keys in `.env.local` (gitignored)
- [x] Add a README with run steps

## Track A: Auth

- [x] Set up the Supabase client
- [x] Sign-up page
- [x] Log-in page
- [x] Log out
- [x] Session / auth state handling
- [ ] Protected-route wrapper
- [x] `profiles` table linked to `auth.users`
- [x] Password recovery UI
- [ ] Live reset-email and password-change verification

## Track B: Groups + Dashboard

- [x] `groups` table
- [x] `group_members` table (creator = owner)
- [x] Basic RLS policies for groups and members
- [x] Create-group form
- [x] Dashboard listing my groups
- [x] Group detail page
- [x] Owner invite links and member joining
- [x] Status check-ins and recent group history

## Current feature: check-in questions

- [x] Local migration, owner editor, member question, and historical snapshots
- [x] Local SQL access checks and simulated browser checks
- [x] Apply hosted migration and run hosted access checks
- [ ] Complete [live browser checks](check-in-prompts.md#live-browser-checklist)
- [ ] Obtain collaborator review after live browser validation

## Next Up

- [ ] Verify the deployed auth, profiles, groups, invites, and check-in flows
- [ ] Choose the next increment toward recurring accountability forms
