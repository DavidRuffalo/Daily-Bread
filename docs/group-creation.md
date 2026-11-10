# Group creation PR

Create a group, give its creator the owner role, and show the groups the
signed-in account belongs to. A group opens a basic detail view with its
name and the account's role; Back to my groups returns to the list. Reloading
returns to the dashboard. Shareable group routes are a later step.

## Accepted MVP decisions

- Members will join through invite links.
- Roles are owner and member.
- Simple check-in forms are the first accountability feature.

Invite creation/redemption and check-ins follow this PR. The current UI has
no member-management controls. Each account can create multiple groups;
group names need not be unique.

## Implementation

- `groups` stores a name, creator, and creation time.
- `group_members` stores membership and the owner/member role.
- `create_group` creates the group and owner membership atomically, using
  the signed-in identity rather than a user ID supplied by the browser.
- The browser can read joined groups and its own membership rows. It cannot
  insert, update, or delete table rows directly or change its role.
- The create form retains its name on failure. Retrying the same name in
  the same mounted form uses the same request ID to avoid duplicates after
  a lost response. After a page reload, check My groups before resubmitting.
- Group state resets on account changes. Load failures offer a retry;
  empty results show an invitation to create the first group.

## Validation

Lint, the production build, and whitespace checks passed on November 10,
2026. The existing bundle-size warning remains. Both profiles and groups
SQL tests passed in isolated PGlite, with all fixtures rolled back. The
groups tests cover creation, owner assignment, owner/member/outsider reads,
denied direct writes and self-promotion, invalid names, missing identities,
duplicate-safe retry, ID collisions, atomic failure, and deletion cascades.

The groups migration was then applied to the hosted `daily-bread` project
matched to the app configuration. Hosted groups access tests passed and
rolled back their fixtures. A read-only follow-up confirmed the migration
record, enabled RLS, authenticated-only RPC execution, denied direct joins,
zero remaining fixture accounts, and zero groups/memberships before browser
testing.

Browser checks still pending:

- Create a named group; confirm it appears with Owner and survives reload.
- Open the group and return to My groups.
- Switch accounts; the first account's group must not appear. Create a
  separate group and verify each account retains only its own groups.
- Reject a name longer than 80 characters; an empty or spaces-only name
  must not submit.
- Block creation, confirm feedback and retained input, unblock and retry.
- Block group loading, confirm feedback, unblock and retry without reload.

Member visibility is covered by SQL fixtures; joining via the UI will be
tested with the invite feature. The deployed groups UI is not yet verified.

## Branch and review

`feature/group-creation` starts from profiles commit `9c783b2`, following
the decision to keep developing while earlier PRs await review. The draft
targets `main` and depends on PR #4, plus its predecessors #3 and #1. After
those dependencies are squash-merged, move only the groups commits onto
updated `main` and recheck the diff. Collaborator approval is required
before merging. The Pages workflow still deploys `feature/app-setup`.
