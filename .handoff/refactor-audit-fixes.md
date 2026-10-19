# refactor/audit-fixes

## Goal
Apply the architecture-audit fixes (13 numbered steps) to the dotfiles repo, one commit per step.

## Status
- [x] 1 git-guard python 3.9 crash
- [x] 2 check.sh fixture (git clean -fdX)
- [x] 3 treesitter redundancy
- [ ] 4 dead code / redundant overrides
- [ ] 5 brewfile claude-code cask
- [ ] 6 ci push only on main
- [ ] 7 move cs() to zshrc.local
- [ ] 8 one source of commit rules
- [ ] 9 lint python in check.sh
- [ ] 10 awsme-sso single sts call
- [ ] 11 merge gitlab review helper
- [ ] 12 skills pruning (report only)
- [ ] 13 bootstrap migration leftovers
- [ ] not pushed, no pr (user decides)

## Decisions
- git-guard: `from __future__ import annotations` instead of `Optional[...]`; keeps modern syntax and works on macOS /usr/bin/python3 (3.9.6).

- check.sh: `git clean -fdXq` on the repo copy (guarded by a rev-parse --show-toplevel check so it can never touch the real worktree); asserts local files are created from templates.
- treesitter: only `jsonc` is not installed by LazyVim base + enabled extras (checked against lazy/LazyVim treesitter.lua and extras/lang/*.lua).

## Gotchas
- shellcheck is not installed on this mac, so check.sh skips lint locally; ci runs it.
- exit 1 from a claude code hook is non-blocking, so an import crash silently disables the guard.

## Key files
- ai/claude/hooks/git-guard.py, scripts/check.sh

## Open questions
- none yet
