# feat/architecture-implementer-agent

## Goal
Global subagent `architecture-implementer` that applies only roadmap steps from reports produced by
`architecture-auditor`, enforced by hooks: it can't be launched for anything else and can't change
files the report doesn't cite.

## Status
- [x] `ai/claude/hooks/audit-gate.py` (record / launch gate / scope / stop check)
- [x] `ai/claude/agents/architecture-implementer.md` + frontmatter hooks; auditor frontmatter Stop hook
- [x] settings.json wiring, check.sh tests (synthetic payloads), README rows; bootstrap re-run locally
- [ ] live test with a real auditor → implementer run (not done; hook payload fields are from the
      docs, not observed)
- [ ] push and open the PR (only when the user asks)

## Decisions
- Registry `~/.claude/audits/<id>.md` + `<id>.json` (repo, created, agent ids); id = sha256[:12] of
  the report. Written only by the hook: when the auditor finishes (global SubagentStop, plus a Stop
  hook in the auditor's frontmatter so `claude --agent architecture-auditor` sessions get recorded too).
  A report is only recorded if all four required sections are there.
- Launch: the implementer's prompt must be exactly `audit: <id|latest>` + `steps: <all|1,3|2-4>`.
  The hook checks that the audit was recorded for the cwd repo, then swaps the prompt for the
  report (`updatedInput`), so the parent can't add work the audit doesn't contain.
- Lease is per repo (`~/.claude/audits/leases/<sha of repo>.json`), not per session, so the hook
  doesn't depend on subagent session_id semantics. One implementer per repo at a time; leases
  expire after 6h.
- Scope = files cited anywhere in the report (backticked paths, `path:line`, globs, braces, bare
  basenames, `dir/` prefixes). Parsing individual roadmap steps was too fragile.
- Edit/Write checked before they run; Bash isn't parsed. Instead, when the implementer stops, the
  hook diffs the repo against the lease's base commit + untracked files, and blocks the stop until
  out-of-scope changes are reverted. Files already dirty at launch and `.handoff/` are exempt.
- No lease → every Bash/Edit/Write from the implementer is denied (covers `claude --agent`).
- The hook denies Edit/Write into `~/.claude/audits`, plus Bash commands that redirect into it or
  name it in a writing command (cd/rm/mv/cp/tee/sed/...). Commands that only mention it (reads,
  docs text) are allowed. This stops accidents or a casual forgery, not a determined attacker with
  a shell (e.g. a python script that writes there).

## Gotchas
- The first version blocked every Bash command that mentioned the path, which blocked my own
  README edits: hooks under `ai/claude/hooks` are live as soon as they're saved (`~/.claude/hooks`
  is a symlink). Use Edit/Write to fix a guard that's blocking Bash.
- Auditor section match is `^#+ .*<name>` because section 4 is "Concrete Before-and-After ...".
- shellcheck is installed on this machine now; ruff isn't (CI runs it).

## Key files
- `ai/claude/hooks/audit-gate.py`, `ai/claude/agents/architecture-{auditor,implementer}.md`,
  `ai/claude/settings.json`, `scripts/check.sh`, `README.md`
