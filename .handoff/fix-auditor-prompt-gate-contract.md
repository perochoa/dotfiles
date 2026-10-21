# fix/auditor-prompt-gate-contract

## Goal
Make the architecture-auditor prompt match what `audit-gate.py` actually parses, so reports get
recorded and the implementer's file scope is what the audit meant.

## Status
- [x] `cited_paths`/`in_scope`: cite root files with no extension (`Makefile`, `.zshrc`) when they
      exist; a bare name now means the root file only, not every file with that basename
- [x] check.sh regression cases (fail on the old hook, pass on the new)
- [x] auditor prompt: verbatim headings, continuous step numbering, full-path citations, cwd-only
      repo, no secret values in reports
- [ ] push and open the PR (only when the user asks)

## Decisions
- Bare-name citations match the repo root only: the old basename match let `README.md` grant
  every README in the repo. A missed nested file is denied and reported, which is the safe side.
- Extensionless bare names count only if the file exists, so prose words in backticks don't
  become scope. A new extensionless root file can't be cited (accepted limitation).
- Recording under the cwd repo stays as is; the prompt documents it instead of the hook guessing
  which repo was audited.

## Key files
- `ai/claude/hooks/audit-gate.py`, `ai/claude/agents/architecture-auditor.md`, `scripts/check.sh`
