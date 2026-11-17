# Git Workflow

## Branches

- `main` stays clean. Never commit to it directly.
- Branch from the latest `main`.
- Name branches `type/short-description`, lowercase with hyphens.
- Allowed types: `feature`, `fix`, `docs`.

Examples: `feature/login-page`, `fix/crash-on-start`, `docs/planning`

## Pull Requests

- One task per pull request, always into `main`.
- Title is a short imperative sentence, e.g. `Add login page`. It becomes the squash commit message.
- Description is brief: a line or two on what changed and why.
- The other person must approve before merging.
- The author merges with **squash merge**. The branch is deleted on merge.
