# Group invite links

Owners open a group, select Create new invite link, and copy the resulting
link. A recipient signs in, reviews the group name, and clicks Join group.
The group then opens with the Member role and appears in My groups.

## Behavior

- Each group has one reusable link, valid for seven days. Creating another
  link replaces the previous one. Revoke invite link disables the current
  link without removing existing members.
- Owner controls are available in the group detail view. The database
  independently enforces ownership; members cannot create or revoke links.
- Opening a link only previews the invitation. Joining requires an explicit
  action and always assigns member. Repeated joins preserve the existing
  role, including an owner's role, without duplicating membership.
- Invalid, expired, replaced, and revoked links show guidance to request a
  new link. A valid preview does not guarantee a later join: the database
  checks again when Join group is clicked.
- Creation, revocation, preview, and joining provide connection feedback
  and allow retries. If automatic copying is unavailable, select and copy
  the link field. Creating again after a lost response replaces that link.

## Links and authentication

Links use the current origin and Vite base path, for example
`http://localhost:5173/Daily-Bread/#invite=<token>`. Local links work on the
computer running the dev server. Public sharing requires the invite UI to
be deployed at the site's public origin.

The token is carried in the URL fragment. The app saves a pending invitation
in session storage for that tab and removes the invite field from the URL,
preserving unrelated hash fields. This supports reloads, login, switching
between signup and login, and selecting a different account. If storage is
unavailable, the fragment remains so a reload can still recover the invite.

New users confirm their email, then return to the original tab or reopen
the invite link. A confirmation link opened in a different tab does not
carry the pending invitation. This keeps the existing email redirect
configuration usable. Dismissing or completing the invitation clears the
pending token. Join responses from an unmounted/account-switched screen
cannot navigate the new account into the previous account's result.

Raw tokens are not stored in the database. The server stores their SHA-256
hashes and exposes invite operations through restricted database functions.
Anyone holding a valid link can join after signing in; links are not tied
to an email address and have no use-count limit in this MVP.

## Verification

On November 11, 2026:

- Lint and the production build passed. The existing bundle-size warning
  remains. Whitespace checks passed.
- All migrations and SQL access tests passed in isolated PGlite. The new
  tests cover owner permissions, anonymous/missing identities, denied
  direct reads and writes, preview without joining, member assignment,
  repeat joins, owner preservation, multiple recipients, invalid/expired
  tokens, replacement, revocation after preview, and group deletion.
- The migration was applied and recorded on hosted `daily-bread`. Hosted
  invite SQL checks passed; a follow-up confirmed permissions and rollback
  of every fixture account, with no invite rows left by the tests.
- A temporary Playwright harness ran against the local app in headless
  Brave with simulated Supabase HTTP responses. It verified owner controls,
  creation/revocation retries, clipboard fallback, base-path link generation,
  signed-out reload persistence, signup/sign-in transitions, preview without
  joining, join retry, Member rendering without owner controls, persistence,
  repeat joins, replacement/revocation/expiry errors, preview retry,
  dismissal cleanup, and preserving Owner on reopening a link. No page
  errors or unexpected network requests occurred. Test tooling was installed
  outside the app, and all Supabase traffic in that browser was intercepted.

The remaining live browser check uses two real test accounts:

1. On the owner account, open a group and create/copy an invite link.
2. Open the link in another browser session, sign in with the second
   account, and join. Confirm Member, no owner invite controls, and the
   group still listed after reload.
3. Reopen the link to check the already-member path. Revoke the link on
   the owner account, then reopen it to check the invalid-link message;
   the member should still have access through My groups.

Live Auth/API integration and the deployed invite UI are not yet verified.
The automated browser checks use simulated responses; SQL tests impersonate
roles in a trusted database session. Neither is a real email/signup test.

## Review and next work

`feature/group-invites` starts from groups commit `e55ad64`. Its draft PR
targets `main` and depends on #5 and its predecessors #4, #3, and #1. After
those dependencies are squash-merged, move only the invite commits onto
updated `main` and verify the diff before marking ready for review.
Collaborator approval is required before merging. The existing Pages
workflow still deploys `feature/app-setup`.

Simple check-in forms are the next MVP feature. Member removal, ownership
transfer, email-specific invites, and invite usage limits are later work.

References: [Supabase database functions](https://supabase.com/docs/guides/database/functions),
[row-level security](https://supabase.com/docs/guides/database/postgres/row-level-security),
and [PostgreSQL SHA-256](https://www.postgresql.org/docs/current/functions-binarystring.html).
