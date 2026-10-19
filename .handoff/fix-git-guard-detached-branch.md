# fix/git-guard-detached-branch

## Goal
git-guard must know the branch while HEAD is detached mid-rebase, so commit-message rules
(`<branch>: ` prefix, subject length after the prefix) and main protection still apply.

## Status
- [x] `current_branch()` falls back to `rebase-merge`/`rebase-apply` `head-name`
- [x] check.sh regression test (detached HEAD + fake rebase-merge state)
- [ ] push and open the PR (waiting on user)

## Decisions
- Read the rebase state via `git rev-parse --path-format=absolute --git-path <state>/head-name`,
  so it works in linked worktrees too (same call session-handoff.py already relies on).
- Rebasing `main` itself now resolves to `main`, so commits and `rebase --continue` there are
  blocked, matching the "never rebase main" rule.

## Gotchas
- Found while rebasing feat/architecture-auditor-agent: with no branch, the prefix counted toward
  the 72-char limit and the prefix rule was skipped.
- The test repo commit needs inline `-c user.name/-c user.email`; CI has no git identity.

## Key files
- `ai/claude/hooks/git-guard.py` (`current_branch`, `check`), `scripts/check.sh` (claude hooks)
