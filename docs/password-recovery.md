# Password recovery

On the sign-in screen, select Forgot password, enter your account email,
and select Send reset email. The confirmation does not disclose whether
an account exists. Open the latest reset email, choose and confirm a new
password, then continue to Daily Bread or sign out.

## Behavior

- The new-password screen takes priority over the profile, groups, and
  any saved invitation. Continuing after success resumes the invitation.
- Matching passwords of at least six characters are required locally.
  Supabase enforces the project's password policy and displays any stricter
  requirements returned by the server. Passwords are not trimmed.
- Refreshing before completion restores the screen using a per-tab user-ID
  marker. The marker is UI state only; Supabase authorizes the password
  update with the authenticated session. Password fields are never saved
  by the app in browser storage. If session storage is unavailable, the
  current page works but recovery-screen restoration is unavailable.
- Sign-out clears recovery state. A marker from another account is ignored
  and cleared. Normal auth refresh events preserve an active recovery form.
- Pending requests disable the form. Failed requests preserve the fields
  for retry. An interrupted password-update response may follow a successful
  server write; the message also directs the user to try the new password
  when signing in. Success clears both password fields and the marker.
- Invalid, expired, or reused email links show guidance even if the browser
  already has a valid session. The app removes the error parameters from
  the address bar without displaying server-provided error descriptions.
- Recovery-link expiration and email rate limits are controlled by Supabase
  Auth. They are separate from the app's seven-day group invitations.

## Setup

No database migration or new dependencies are needed. The reset request
uses the existing Vite base URL on the current origin as its redirect:

- Local: `http://localhost:5173/Daily-Bread/`
- Pages: `https://davidruffalo.github.io/Daily-Bread/`

Keep these in Supabase Auth's redirect allowlist. The normal Supabase reset
email template must retain its confirmation link. The SDK processes the
callback, removes the session tokens from the URL, and emits
`PASSWORD_RECOVERY`; the app then calls `updateUser` on explicit submission.
See the [official Supabase reset-password API](https://supabase.com/docs/reference/javascript/auth-resetpasswordforemail).

The existing Pages workflow still deploys `feature/app-setup`. This feature
branch has not been deployed or merged into main.

## Verification

On November 12, 2026, lint, the production build, and whitespace checks
passed. The existing bundle-size warning remains.

A temporary Playwright harness in headless Brave used the local app and
real Supabase JavaScript SDK with all Supabase responses intercepted.
It verified:

- Reset request, exact project redirect, generic confirmation, another-email
  control, offline retry, and server rate-limit guidance.
- Recovery callback, token removal, refresh restoration, short-password and
  mismatch validation without an update request, update errors, retry,
  success, cleared fields, and normal home restoration.
- Sign-out/cancellation, account switching, stale-marker isolation, and
  expired/reused-link guidance while signed in and signed out.
- Recovery before a saved invitation, followed by the original invitation.
- No uncaught page errors or unexpected external requests.

No real emails were sent or account passwords changed by automated tests.
Tooling and fixture accounts stayed outside the app. The existing check-in
browser regression suite was also run with simulated responses.

Live email delivery, hosted password change, and deployed-browser behavior
remain unverified. To verify locally with an account you control:

1. Sign out, request a reset email, and open its link with the local server
   running. Confirm that Choose a new password appears.
2. Refresh once, then set and confirm a new password. Confirm success.
3. Sign out and sign in with the new password. Verify the old password is
   rejected on a separate signed-out attempt.
4. Reopen the used email link and check the guidance. If you already have
   a valid session, it should remain usable.

## Review dependency

This branch starts at `c0a469a` on `feature/group-check-ins` and depends on
PR #7 and its predecessors. After those PRs are reviewed and squash merged,
move only the password-recovery commits onto the updated main branch before
final review. Do not merge the stacked dependency commits again.
