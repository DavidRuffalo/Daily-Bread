# Daily Bread app setup

Date: October 17, 2026

We set up the React application and installed the libraries for the first login feature. This is a working frontend checkpoint. Login is not implemented yet.

## What changed

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
- `src/App.tsx`: starter page with the MUI counter button.
- `src/App.css`, `src/index.css`, `src/assets/`, and `public/`: generated starter styles and assets.
- `vite.config.ts`: Vite's React configuration.
- `tsconfig.json`, `tsconfig.app.json`, and `tsconfig.node.json`: TypeScript settings.
- `eslint.config.js`: code checks.
- `.gitignore`: excludes dependencies, build output, and local configuration.
- `.env.example`: public connection-setting placeholders.
- `README.md`: generated Vite documentation.

The existing license was preserved. Local `main` already had a separate commit adding Chris's name to the license; the app branch includes that commit too.

## How to run it

After the app branch is available in your checkout:

1. Install Node.js LTS if needed.
2. Run `npm.cmd ci` from the repository root. This installs the dependency versions recorded in the lockfile. On systems without the Windows `.cmd` wrapper, use `npm ci`.
3. Copy `.env.example` to `.env.local` and replace the placeholders with the Daily Bread project's URL and publishable key from Supabase.
4. Run `npm.cmd run dev` and open the Local URL printed in the terminal.
5. Click the counter to verify the page responds.

Keep the development server running while using the page. Press Ctrl+C to stop it. Restart it after changing environment settings.

## Configuration and security

- `.env.local` is ignored by Git through the existing `*.local` rule. Each developer supplies their own local file.
- `VITE_` values are available to browser code. Ignoring a configuration file does not make the bundled values secret.
- Use only the project URL and publishable key in this frontend. Never add a secret key or legacy service-role key.
- At this checkpoint, the local URL value contained an extra `=` and failed HTTPS URL validation. Correct it before testing the connection. The format is `VITE_SUPABASE_URL=https://your-project-ref.supabase.co`, with one `=` and the actual project reference.
- Checking a key's prefix does not prove that it belongs to the correct project. A live connection has not been tested.

## What we verified

- Node.js and npm print their installed versions.
- Dependency installation completed with no vulnerabilities reported by npm at installation time.
- The developer confirmed the starter page loads and the counter increases.
- The developer confirmed the MUI counter button renders and still works.
- `npm.cmd run lint` passed.
- `npm.cmd run build` passed, including TypeScript compilation and the Vite production build.
- Git ignores `.env.local`, `node_modules`, and `dist`.
- Configuration checks printed only validation results, not the actual URL or key. The key has a publishable prefix; the URL check still needs to pass.

## Next session

1. Correct the local URL and verify the configuration without printing its values.
2. Create a shared Supabase client that reads the environment settings.
3. Configure trusted test-account creation and the initial authentication settings in Supabase.
4. Build basic sign-in, session handling, a signed-in screen, and logout, one small step at a time.

Routing, a Supabase client module, authentication screens, database tables, and RLS policies have not been added. Roles and permissions are deferred until needed, before exposing private data or protected admin actions.

## Branches and handoff

- Application files and `.env.example` are on `feature/app-setup`.
- This note is on `doc/planning`, in a separate Git worktree so both branches can be reviewed independently.
- Commit and push the application and documentation changes separately before opening their pull requests. Neither branch has been merged at this checkpoint.
- Follow `docs/git-workflow.md`: commit on the respective branches, open pull requests into `main`, get the other person's approval, and squash merge. Review the existing license commit included in the app branch as well.
- Once both changes are merged, the setup note and application files will be available together on `main`.
