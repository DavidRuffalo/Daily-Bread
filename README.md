# Daily Bread

A web app for small groups to stay consistent with shared goals,
habits, and commitments.

Built with React, TypeScript, Vite, Material UI, and Supabase.

## Current functionality

- Email/password sign-in with an existing account
- Signed-in screen showing the current user's email
- Session restoration after refreshing
- Sign-out for the current session
- Loading states and authentication error messages

Signup, password reset, profiles, and group features are planned.

## Requirements

- Node.js and npm
- A Supabase project
- That project's URL and publishable key
- A confirmed test account in that project

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

## Test account

A project maintainer can create a development account through
Supabase → Authentication → Users → Add user → Create new user.

Use an email you control and a private test password. Auto Confirm User
can mark this specific test account as confirmed without an email link.
This does not test the email-verification flow.

The app currently supports sign-in with existing accounts.

## Check the app

```powershell
npm.cmd run lint
npm.cmd run build
```

Manually verify:

- Correct credentials open the welcome screen.
- Refreshing keeps the user signed in.
- Sign out returns to the login form.
- Refreshing after sign-out keeps the user signed out.
- An incorrect password displays an error.

## Planning docs

Project planning and the ongoing app-setup handoff are currently
maintained on the separate `doc/planning` branch.