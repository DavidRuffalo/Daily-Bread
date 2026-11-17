# Daily Bread app setup

Last reviewed: October 19, 2026

This is the ongoing handoff for the app-setup work on `feature/app-setup`, maintained with the planning docs on `doc/planning`. Keep this document current across sessions rather than creating session-specific notes. PR number and remote review status have not been verified.

We set up the React application and installed the libraries for the first login feature. Email/password sign-in now works with the manually created test account. Session-aware UI, refresh restoration, and logout now work too. The functional checkpoint and app README are complete. App commit `df2c3e8` has been pushed to `origin/feature/app-setup`; planning-doc publication and PR review remain.

David wants to learn through small, explained steps. Explain each change and let him participate; do not automatically execute the remaining setup or implement the next feature. "Admin stuff" currently means Supabase account/project setup, not an in-app admin dashboard.

## PR goal and stopping point

Goal: another developer can run Daily Bread locally and use an existing Supabase test account to sign in, retain the session after refresh, and sign out, with pending state and error feedback.

The functional goal is met based on the saved code, passing build/lint, and David's manual browser checks. Suggested PR title: `Set up the app with Supabase sign-in`. Signup, email verification flows, password recovery, profiles, groups, admin roles, protected routing, and database/RLS work belong in later changes. Switching the displayed screen based on the session is not a database authorization policy.

David formatted the application files and replaced the template README with project run/configuration and test-account instructions. The five app files were reviewed, committed as `df2c3e8`, and pushed. Commit and push the planning-doc changes separately, then open or update the respective PRs into `main`. The other collaborator must approve before squash merging.

## Current checkpoint

- David confirmed the Supabase Users list was initially empty, then confirmed that his manually created test account appeared. Credentials were not shared or recorded.
- David reports that Allow new users to sign up, the Email provider, and Confirm Email are enabled. These are user-reported dashboard observations, not independently inspected settings.
- `src/lib/supabase.ts` reads the Vite environment values, checks they are present, and exports one shared client. Build and lint passed after this file was added; that does not prove a live connection.
- `src/components/LoginForm.tsx` contains controlled email/password fields. `src/App.tsx` now renders it.
- `src/main.tsx` applies an MUI dark ThemeProvider and CssBaseline. It no longer imports the starter `index.css`; David confirmed the fields and heading are readable after this change.
- `LoginForm.tsx` now submits through `supabase.auth.signInWithPassword`, prevents the default page reload, disables the button while pending, shows feedback, and clears the password after success. David reported "Signed in successfully!" after testing his account; the saved implementation was reviewed.
- `App.tsx` subscribes to auth changes, cleans up the subscription, shows the current user when signed in, and signs out the current session with pending/error state.
- David confirmed the welcome screen survives refresh, logout returns to the form, refreshing after logout stays signed out, an incorrect password shows an error, and the correct password signs in again. These are user-reported browser checks.
- Final `npm.cmd run build` and `npm.cmd run lint` pass with the session/logout code. Vite reports a non-fatal bundle-size warning for the roughly 646 kB minified JavaScript chunk. Email delivery, signup, password recovery, session expiry, and network-failure behavior have not been tested.
- David committed the five app files as `df2c3e8` (`Add Supabase sign-in and session handling`) and pushed `feature/app-setup` to GitHub. Local Git confirms the app worktree is clean and the tracking branch matches. Remote PR/merge status has not been inspected.
- David ran `npm.cmd ci`: 228 packages installed and npm reported 0 vulnerabilities at that time. Build, lint, and `git diff --check` passed after that clean install.
- The README now covers project purpose, existing auth features, requirements, local environment setup, development commands, test-account creation, and manual smoke checks.

## Initial setup

- Installed Node.js 24.20.0 and npm 11.19.0 on David's computer. These are development tools, not repository files.
- Created `feature/app-setup` from the updated local `main` branch.
- Generated a React and TypeScript application with Vite and ESLint in the repository root.
- Installed the application dependencies and generated `package-lock.json`.
- Installed MUI with its Emotion styling dependencies.
- Replaced the starter counter's HTML button with MUI's `Button`, using `variant="contained"`. The existing counter state and click handler still work.
- Installed `@supabase/supabase-js`.
- Created a local `.env.local` for the existing Daily Bread Supabase project's URL and publishable key.
- Added `.env.example` with placeholders so another developer knows which settings to provide.

## Files in the app branch

- `package.json` and `package-lock.json`: dependencies, scripts, and resolved dependency versions.
- `index.html` and `src/main.tsx`: HTML entry point and React startup.
- `src/App.tsx`: tracks the session, displays login or the signed-in view, and handles logout.
- `src/components/LoginForm.tsx`: email/password sign-in with pending state and feedback.
- `src/lib/supabase.ts`: shared Supabase client with required-setting checks.
- `src/App.css`, `src/index.css`, `src/assets/`, and `public/`: generated starter styles and assets.
- `vite.config.ts`: Vite's React configuration.
- `tsconfig.json`, `tsconfig.app.json`, and `tsconfig.node.json`: TypeScript settings.
- `eslint.config.js`: code checks.
- `.gitignore`: excludes dependencies, build output, and local configuration.
- `.env.example`: public connection-setting placeholders.
- `README.md`: project setup, environment configuration, test-account instructions, and verification steps.

The existing license was preserved. Local `main` already had a separate commit adding Chris's name to the license; the app branch includes that commit too.

## How to run it

After the app branch is available in your checkout:

1. Install Node.js LTS if needed.
2. Run `npm.cmd ci` from the repository root. This installs the dependency versions recorded in the lockfile. On systems without the Windows `.cmd` wrapper, use `npm ci`.
3. If `.env.local` does not exist, copy `.env.example` to it. Fill in the Daily Bread project URL and publishable key from Supabase; preserve any existing local configuration.
4. Run `npm.cmd run dev` and open the Local URL printed in the terminal.
5. Confirm the sign-in heading and email/password fields appear and accept typing.

Keep the development server running while using the page. Press Ctrl+C to stop it. Restart it after changing environment settings.

## Configuration and security

- `.env.local` is ignored by Git through the existing `*.local` rule. Each developer supplies their own local file.
- `VITE_` values are available to browser code. Ignoring a configuration file does not make the bundled values secret.
- Use only the project URL and publishable key in this frontend. Never add a secret key or legacy service-role key.
- The October 17 URL issue is no longer reproduced: on October 19, Vite-loaded configuration passed HTTPS URL validation with a Supabase hostname. No configuration values were changed during that review.
- A key-prefix check alone does not validate a project/key pair. David has now reported a successful live sign-in using the configured client and his test account.

## What we verified

- Node.js and npm print their installed versions.
- Dependency installation completed with no vulnerabilities reported by npm at installation time.
- The developer confirmed the starter page loads and the counter increases.
- The developer confirmed the MUI counter button renders and still works.
- `npm.cmd run lint` passed.
- `npm.cmd run build` passed, including TypeScript compilation and the Vite production build.
- Git ignores `.env.local`, `node_modules`, and `dist`.
- October 19 configuration checks printed only validation results, not the actual URL or key. The key has a publishable prefix and URL format validation passes. A later successful sign-in was reported by David, as recorded in the current checkpoint.
- Build and lint both passed again on October 19. Use `npm.cmd` in PowerShell because the `npm.ps1` wrapper is blocked by the execution policy.
- Supabase dashboard findings are reported by David, as recorded above. The assistant has not independently inspected the dashboard or changed remote settings.

## Remaining work

1. Review, commit, and push the updated planning docs on `doc/planning`.
2. Open or update the app and planning PRs into `main`, describing the final scope and completed validation.
3. Have the other collaborator review and approve; follow the documented squash-merge workflow.
4. Keep signup, email verification, redirect configuration, password recovery, and data features for separately scoped work.

A session-aware screen is present. Routing, database tables, and RLS policies have not been added. Roles and permissions are deferred until needed, before exposing private data or protected admin actions.

## Where to resume

The application checkpoint is committed and pushed. Resume with the planning-doc commit/push and GitHub PR preparation. GitHub CLI was not found in this shell, so guide the GitHub web workflow unless tooling changes. Check whether PRs already exist before creating duplicates. David still wants to make and understand application and Git steps himself.

As work progresses, update this document with completed steps, decisions, checks, and the exact next action. Read `daily-bread.md`, `TODO.md`, and `git-workflow.md` alongside it for broader scope and workflow. Keep credentials out of these notes.

## Branches and handoff

- Application files and `.env.example` are on `feature/app-setup`.
- This note is on `doc/planning`, in a separate Git worktree so both branches can be reviewed independently.
- The app branch is pushed through `df2c3e8`. Planning docs are maintained separately on `doc/planning`; verify its commit/push status with Git before continuing. Remote PR and merge status remain unverified.
- Follow `docs/git-workflow.md`: commit on the respective branches, open pull requests into `main`, get the other person's approval, and squash merge. Review the existing license commit included in the app branch as well.
- Once both changes are merged, the setup note and application files will be available together on `main`.
