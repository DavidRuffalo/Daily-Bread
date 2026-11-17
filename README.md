# Daily Bread

A web app for small groups to stay consistent with shared goals,
habits, and commitments.

Built with React, TypeScript, Vite, Material UI, and Supabase.

## Current functionality

- Email/password signup with confirmation-email instructions
- Navigation between sign-in and signup
- Email/password sign-in with an existing account
- Signed-in screen showing the current user's email
- Session restoration after refreshing
- Sign-out for the current session
- Loading states and authentication error messages
- Load, edit, and clear your display name on the signed-in screen
- Create a group and automatically become its owner
- List your groups and open a basic group detail view

Password reset, group invite links, and simple check-ins are planned.

## Requirements

- Node.js and npm
- A Supabase project
- That project's URL and publishable key
- An email address you control for testing signup and confirmation

Development has been verified with Node.js 24.20.0 and npm 11.19.0.

## Run locally

Run these commands from the repository root.

1. Install the dependency versions recorded in the lockfile:

   ```powershell
   npm.cmd ci
   ```

2. If `.env.local` does not already exist, create it:

   ```powershell
   Copy-Item .env.example .env.local
   ```

3. In `.env.local`, fill in your project's settings:

   ```dotenv
   VITE_SUPABASE_URL=https://your-project-ref.supabase.co
   VITE_SUPABASE_PUBLISHABLE_KEY=sb_publishable_your-key-here
   ```

   These values are available to browser code. Use the publishable key,
   never a secret or service-role key. `.env.local` is ignored by Git.

4. Start the development server:

   ```powershell
   npm.cmd run dev
   ```

5. Open the Local URL printed in the terminal.

Restart the server after changing environment settings.
Press Ctrl+C to stop it.

On macOS or Linux, use `npm` instead of `npm.cmd`.

## Signup configuration

In Supabase, enable email signup and email confirmation. Under
**Authentication > URL Configuration**, set:

- **Site URL:** `https://davidruffalo.github.io/Daily-Bread/`
- **Redirect URLs:** `http://localhost:5173/Daily-Bread/` and
  `https://davidruffalo.github.io/Daily-Bread/`

Use the actual Vite port if it differs from `5173`. The app requests a
confirmation redirect to the current origin plus Vite's `/Daily-Bread/`
base path. Keep the local server running when testing a local confirmation
link. See [Supabase's redirect configuration](https://supabase.com/docs/guides/auth/redirect-urls).

Choose **Create an account** on the sign-in screen and use an email you
control. After submitting, follow the confirmation link in your inbox,
then sign in. The app clears the password and disables further signup
submissions while showing the confirmation instructions.

## Manually created test account

A project maintainer can create a development account through
Supabase → Authentication → Users → Add user → Create new user.

Use an email you control and a private test password. Auto Confirm User
can mark this specific test account as confirmed without an email link.
This does not test the email-verification flow.

## Check the app

```powershell
npm.cmd run lint
npm.cmd run build
```

Manually verify:

- The sign-in and signup screens can navigate to each other.
- Signup with a new email shows confirmation instructions and clears the password.
- The confirmation email arrives and its link returns to the app.
- The confirmed account can sign in.
- Correct credentials open the welcome screen.
- Refreshing keeps the user signed in.
- Sign out returns to the login form.
- Refreshing after sign-out keeps the user signed out.
- An incorrect password displays an error.
- A rejected signup displays an error and allows another attempt.
- An offline signup request shows connection and retry guidance, then enables the form again.
- An expired or already-used confirmation link shows an explanation on the sign-in screen.
- A saved display name appears in the welcome message and survives refreshing.
- Clearing the display name saves an unset name and restores the default heading.
- A profile load or save failure provides feedback and allows retrying.

On November 10, 2026, David reported successful local browser checks for
form navigation, signup feedback and password clearing, email delivery,
confirmation-link return, sign-in with the new account, session persistence
after refresh, and sign-out followed by a signed-out refresh. A one-character
password was rejected with a minimum-six-character error, and David confirmed
the form remained editable afterward. Offline signup displayed connection
and retry guidance, and the submit button became available again, as shown
in David's browser screenshot. David also verified that an already-used
confirmation link returning `error_code=otp_expired` displayed guidance on
the sign-in screen, removed the error fields from the URL, and still allowed
normal sign-in afterward. A newly expired link and the deployed signup flow
have not yet been verified.

The profiles migration and hosted SQL access checks have passed. On November 10,
2026, David verified saving a display name and retaining it after reload,
clearing the name and retaining the empty field and default heading after
reload, and reading and updating separate names across two accounts without
overwriting either account's profile. An offline save displayed an error,
retained the draft name and previous welcome heading, and enabled another
attempt. After restoring the connection, David saved the draft successfully
and verified it after reload. David also verified that a freshly signed-up
account loaded the empty profile form. A subsequent hosted read-only check
confirmed three accounts, three profiles, and no accounts missing profiles.
Blocking the profile-load request displayed an error and retry button.
After disabling the block, David verified that retry restored the saved
profile without refreshing. The deployed profile UI has not yet been
verified. See
[`supabase/README.md`](supabase/README.md) for database setup and verification.

## GitHub Pages

The app is published at https://davidruffalo.github.io/Daily-Bread/.
The deployment workflow builds and publishes pushes to `feature/app-setup`.

One-time repository setup:

1. In **Settings > Pages**, set **Source** to **GitHub Actions**. Vite needs
   a build step; publishing the source branch directly does not build the app.
2. In **Settings > Secrets and variables > Actions > Variables**, add
   `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY` using the same
   public browser settings as `.env.local`. Never use a secret or service-role key.
3. Push to `feature/app-setup`, then check **Actions > Deploy to GitHub Pages**.

Vite's base path is `/Daily-Bread/` so built assets load at the project URL.
The workflow fails before publishing if either Supabase setting is missing.

## Planning docs

Project planning and the ongoing app-setup handoff are currently
maintained on the separate `doc/planning` branch.

Database migrations and access-check instructions are in
[`supabase/README.md`](supabase/README.md).

The groups PR scope, decisions, and remaining browser checks are recorded in
[`docs/group-creation.md`](docs/group-creation.md).
