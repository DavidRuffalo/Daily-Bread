# Check-in questions

Group owners can save one question for their group's check-in form. Members
answer it with the existing On track / Need support status and short update.
The default is "Share how you are doing with your goals."

## Behavior

- Owners see a Check-in question field above the posting form. Questions
  are trimmed and must contain 1 to 300 characters, including a nonblank
  character. A failed save keeps the draft and allows another attempt.
- Members see the saved question when opening the group. Refresh check-ins
  reloads the question and history while preserving their answer draft.
- Every check-in stores its question. Editing the current question leaves
  previous posts unchanged. Existing posts get the original default question.
- If the question changes before a member posts, the server rejects the
  stale submission. Refresh check-ins, review the question, and then post.
- An unchanged retry after a lost response reuses its request ID and original
  question, including after refreshing to a new question. A committed post
  is returned once; a stale uncommitted request must be reviewed and retried.
- Navigation away or reloading still resets the answer draft and request ID.
  Inspect recent history before resubmitting after an uncertain response.
- The question and updates are plain text. Recurring schedules, multiple
  questions, and custom answer types remain later work.

## Database setup

Apply `supabase/migrations/20261118000000_add_check_in_prompts.sql` before
using this version of the UI. It adds `groups.check_in_prompt`, the historical
`check_ins.prompt` column, and the owner-only `set_check_in_prompt` RPC.
Existing RLS and denied direct writes remain in force. The server checks
ownership; hiding the editing form is only a UI convenience.

`submit_check_in` accepts an optional `expected_prompt` argument. This UI
sends the displayed question. Four-argument calls from older clients still
work and snapshot the current server question without stale-question checks.
Membership is checked before replaying an existing post. New posts lock the
group row while reading the question and inserting, serializing owner edits.

See [database setup](../supabase/README.md) for migration commands. This
migration was applied to hosted `daily-bread` and recorded in migration
history on November 18, 2026.

## Verification

On November 18, 2026, all five migrations and all five SQL access suites
passed in isolated PGlite with a minimal Auth schema. All fixture users
rolled back. An upgrade check also preserved a preexisting group and answer
with the original default question. The new suite checks default questions,
owner edits, member reads/posting, anonymous/member/outsider/missing-identity denial, direct
write denial, whitespace and length validation, 300-character Unicode
questions, historical snapshots, stale submissions, and committed retries.

A temporary Playwright harness used the local app and real Supabase SDK
with intercepted responses in headless Brave. Checks passed for owner
editing, member display, validation, offline save and retry, persistence
after reload, historical questions, stale submissions preserving drafts,
refresh and review, literal text rendering, and lost-response replay after
an owner edit. The existing check-in browser regression suite also passed
with the additional question-read response simulated. No uncaught page
errors or unexpected external requests occurred. Tooling stayed outside
the repository, and no hosted data was changed by these tests.

Lint, the production build, and whitespace checks passed. The existing
bundle-size warning remains.

The migration was then applied to hosted `daily-bread`. Both the new
`check_in_prompts_access.sql` suite and the existing `check_ins_access.sql`
suite passed there, including four-argument submission compatibility.
Read-only verification confirmed the migration record, RLS, authenticated-only
RPC execution, denied direct prompt/snapshot updates, and no remaining fixture
accounts. The four existing groups and five check-ins were preserved with
the original default question. These SQL checks impersonate roles in a
trusted database session; they do not test browser authentication or the
Supabase HTTP API.

On November 18, 2026, David confirmed in his local browser against hosted
Supabase that an owner-edited question persisted after reloading. On November
20, 2026, David also confirmed that a separate member account could see the
owner's saved question. He then posted a check-in from the member account
and confirmed that refreshing check-ins on the owner account displayed
the member's answer with the correct question. With a member draft left open,
he changed the question as owner, then confirmed that posting from the member
account showed the question-changed message and retained the draft.
He then confirmed that Refresh check-ins displayed the new question, kept
the draft, and allowed a successful post after reviewing the question.
Historical questions after an owner edit, offline save/retry, group isolation,
and deployed feature checks remain pending.

## Live browser checklist

After applying the migration and running its rolled-back access suite:

1. Completed: David confirmed that an owner-edited question persists after reload.
2. Completed: the member sees the saved question and can post an answer;
   the owner sees that answer with the correct question after refreshing check-ins.
3. Stale-question rejection, draft retention through refresh, and successful
   posting after reviewing the new question are confirmed. Still to check:
   earlier posts keep their original question.
4. Save a question while offline. Confirm feedback and draft retention, then
   reconnect and retry. Confirm another group keeps its own question.

The branch is based on merged `main` at `17278f4`. Collaborator review is
required before merging. Pages deploys after a merge to `main`.
