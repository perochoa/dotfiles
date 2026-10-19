# feat/architecture-auditor-agent

## Goal
Global Claude Code subagent `architecture-auditor`: read-only audit of a codebase against stack
best practices plus a KISS/YAGNI simplification pass, reported as executive summary, best
practices audit, roadmap, and before/after code examples.

## Status
- [x] `ai/claude/agents/architecture-auditor.md`
- [x] bootstrap links each agent into `~/.claude/agents/<name>.md`; check.sh asserts it
- [x] README table row
- [ ] user pushes and opens the PR

## Decisions
- Agents linked one file at a time (like skills) because Claude Code's `/agents` UI writes its own
  agents into `~/.claude/agents`; linking the whole directory would put those in the repo.
- Tools limited to Read/Grep/Glob/Bash: the agent reports, it never edits. Bash is for
  `git log`, file counts, and dependency manifests; the prompt forbids mutating commands.
- `model: opus` because the job is deep whole-repo reasoning, not speed.

## Key files
- `ai/claude/agents/architecture-auditor.md`, `bootstrap.sh`, `scripts/check.sh`, `README.md`
