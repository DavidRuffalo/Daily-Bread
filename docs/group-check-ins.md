# Group check-ins

Group owners and members open their group, choose On track or Need support,
and write a short update. Posting adds the check-in to the recent group
history with the author's display name and posting time. The form states
that the name and update are visible to members of that group.

## First-version scope

- A fixed form with a required status and a required update of 1 to 1,000
  characters. Multiple check-ins are allowed; there is no daily limit or
  recurring schedule yet.
- The latest 20 check-ins appear newest first. Refresh check-ins reloads
  the history, preserving an unfinished draft. Older rows stay stored;
  pagination and older-history browsing are later work.
- Current members see the group's history, including posts from before
  they joined. Members outside the group cannot read or post to it.
- The server uses the signed-in account as author and snapshots its saved
  display name when posting. An unset name displays as Group member. Name
  changes do not rename historical posts. Private profile access is
  unchanged; email addresses are not published through this feature.
- Submitted check-ins have no editing or deletion controls. Administrative
  deletion of a group or account removes the associated check-ins. Removing
  membership prevents further reading/posting but retains existing posts.
- Failed posts retain the selected status and note. An unchanged retry in
  the same mounted form reuses its request ID, preventing duplicates after
  a lost response. After navigating away or reloading, inspect the history
  before resubmitting. Dismissing a group or switching accounts resets its
  draft and history state.

## Database boundary

`check_ins` has row-level security and authenticated SELECT grants. Its read
policy checks current group membership. `submit_check_in` is the only client
write path: it checks and locks membership, validates the payload, derives
the author/name/time, and inserts or returns an identical earlier request.
The function uses an empty search path and authenticated-only execution.
Direct client inserts, updates, and deletes are denied for owners and
members. Knowing a group/check-in ID grants no additional access.

## Verification

On November 12, 2026:

- Lint, production build, and whitespace checks passed. The existing bundle
  size warning remains.
- All four migrations and all four SQL access suites passed in isolated
  PGlite. Check-in tests cover owner/member posting and shared reads, group
  isolation, anonymous/missing identities, membership removal, protected
  fields, name snapshots/fallback, both statuses, empty/whitespace/overlong
  updates, 1,000-character Unicode updates, unchanged retries, conflicting
  request IDs, and deletion cascades. All fixtures rolled back.
- The migration was applied and recorded on hosted `daily-bread`. Hosted
  check-in tests passed, and the read-only follow-up confirmed permissions,
  RLS, migration history, zero fixture users, and zero stored check-ins
  before live browser testing.
- A temporary Playwright harness ran against the local app in headless
  Brave with simulated Supabase responses. It checked the empty state,
  required fields, whitespace/length validation, shared owner/member reads
  and posts, reload persistence, draft retention, load/post failures and
  retry, an actual simulated lost-response replay with one post, safe
  literal text rendering, the newest-first 20-row limit, group/account
  resets, and isolated histories. No page errors or unexpected requests
  occurred. Tooling and fixtures stayed outside the app, and all Supabase
  browser traffic was intercepted.

Remaining live browser check:

1. Open a group on the owner account, choose On track, and post an update.
   Confirm the saved name/status/text and that the update survives reload.
2. On a second account that joined the same group, open it and verify the
   first update. Post a Need support update, then refresh check-ins on the
   owner account to confirm it is shared.
3. Open a separate group to confirm its history stays separate. An offline
   post should preserve the draft and allow retry after reconnecting.

Live Auth/API integration and the deployed check-in UI remain unverified.
The SQL tests impersonate roles in a trusted database session, and automated
browser tests use simulated API responses.

## Review

`feature/group-check-ins` starts from invite commit `67a98fc`, following the
agreed workflow of continuing while predecessor PRs await review. Its draft
targets `main` and depends on #6 and its predecessors #5, #4, #3, and #1.
After dependencies are squash-merged, move only check-in commits onto
updated `main` and verify the diff before marking ready for review.
Collaborator approval is required before merging. The Pages workflow still
deploys `feature/app-setup`.

After live validation, the next milestone is collaborator review and
validation of the deployed features. Owner-defined prompts, recurring
forms, reminders, progress tracking, and older-history browsing are later
work.

References: [Supabase database functions](https://supabase.com/docs/guides/database/functions)
and [row-level security](https://supabase.com/docs/guides/database/postgres/row-level-security).
