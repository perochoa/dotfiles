# feat/architecture-auditor-agent

## Goal
Global Claude Code subagent `architecture-auditor`: read-only audit of a codebase against stack
best practices plus a KISS/YAGNI simplification pass, reported as executive summary, best
practices audit, roadmap, and before/after code examples.

## Status
- [x] `ai/claude/agents/architecture-auditor.md`
- [x] bootstrap links each agent into `~/.claude/agents/<name>.md`; check.sh asserts it
- [x] README table row
- [x] rebased onto main after refactor/audit-fixes (#6) merged
- [ ] push and open the PR

## Decisions
- Agents linked one file at a time (like skills) because Claude Code's `/agents` UI writes its own
  agents into `~/.claude/agents`; linking the whole directory would put those in the repo.
- Tools limited to Read/Grep/Glob/Bash: the agent reports, it never edits. Bash is for
  `git log`, file counts, and dependency manifests; the prompt forbids mutating commands.
- `model: opus` because the job is deep whole-repo reasoning, not speed.
- Read-only rule names commands that look read-only but write (brew auto-update, `__pycache__`,
  hooks touching `.git/info/exclude`), and leaves handoff docs to the parent session: the first
  real audit of this repo ran into these.
- Rebase kept main's trimmed stale-link loop (skills only) and added `~/.claude/agents/*` to it;
  check.sh's symlink list keeps main's `gitlab-cli` (python-patterns was pruned).

## Key files
- `ai/claude/agents/architecture-auditor.md`, `bootstrap.sh`, `scripts/check.sh`, `README.md`
