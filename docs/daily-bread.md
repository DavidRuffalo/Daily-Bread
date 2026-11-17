# Daily Bread

A web app that helps small groups stay consistent with shared goals, habits, and commitments. The first audience is Christian communities and Bible study groups. Other uses, such as studying, fitness, or personal habits, can come later.

> This doc is meant to stay short. We add detail as we make decisions.

## Stack

- **Frontend:** React + Vite
- **Backend / Auth / DB:** Supabase

## MVP Focus

Two tracks we can build in parallel:

**Track A: Auth**
- Sign up, log in, log out
- Protected routes
- A user profile row for each account

**Track B: Groups + Dashboard**
- Create a group
- Bare-bones dashboard showing "my groups"
- Group page (stub to start)

The dashboard starts as a shell. New pieces get added to it as each feature lands.

## Decided

- **Groups only for now.** Communities above groups come later.
- **Message-board style communication**, not real-time chat, when we get to it.

## Open Decisions

- What is the first core accountability feature after group creation? (check-in forms, invites, message board, ...)
- How do members join a group? (invite link, email, code)
- How much of the roles/permissions system goes in the MVP? (owner vs. member only?)

## Later / Backlog

- Communities containing multiple groups
- Co-admins and per-feature permissions
- Customizable recurring accountability forms
- Progress tracking: streaks, completion history, other metrics
- Message board
- Prayer board with visibility levels (community, group, admins, private)
- Automated email reminders
- Advanced analytics
- More notification methods
- Expanded privacy controls

## See Also

- [TODO.md](TODO.md): current checklists
- [git-workflow.md](git-workflow.md): how we branch and open PRs
