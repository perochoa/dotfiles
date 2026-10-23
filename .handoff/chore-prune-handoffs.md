# chore/prune-handoffs

## Goal
Delete handoff docs for branches already merged (#6–#15), keeping only follow-ups still open.

## Status
- [x] removed 10 merged handoffs; corrections log entry updated to "pr #15"
- [ ] push and open the PR (only when the user asks)

## Open follow-ups (carried over from the deleted docs)
- [ ] live end-to-end run: `architecture-auditor` → `architecture-implementer` in a real session.
      `audit-gate.py` is only tested with synthetic payloads in check.sh, plus a replay of two
      real auditor runs; launch/lease/stop on real implementer payloads is unobserved.
- [ ] other machine: re-run `./bootstrap.sh` and open a new shell to confirm zsh plugins load
      and `~/.aws/config` links to `aws/config.local` (from #11).

## Key files
- `ai/claude/hooks/audit-gate.py`, `shell/env.zsh`, `bootstrap.sh`
