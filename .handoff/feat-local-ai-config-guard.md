# feat/local-ai-config-guard

## Goal
AI assistant config (`CLAUDE.md`, `CLAUDE.local.md`, `AGENTS.md`, `.claude/`) stays local
(`.git/info/exclude`) unless the repo already has it on its remote. Codified from a repeated
correction (CS4411 2026-10-18, cs4472-group6-a1 2026-10-22).

## Status
- [x] global rule: `ai/AGENTS.md` "AI assistant config"
- [x] `git-guard.py`: blocks `git add` (incl. `-f`) and `git commit` (staged, or `-a`) of such files
      the repo doesn't have; check.sh regression tests; `./scripts/check.sh` passes
- [ ] user approves push + PR into main
- [ ] after merge: drop "(… not merged yet)" from the 2026-10-22 cs4472 entry in
      `ai/corrections.local.md`

## Decisions
- "Repo already has it" = tracked on `origin/HEAD` (fallback `origin/main`/`origin/master`),
  or in `HEAD` when there's no remote. Teammates' shared files are then editable as usual.
- Opt-out per repo: `git config ai.shareAgentConfig true` (for when the user asks to share).
- `git add .`/`-A` aren't inspected (excluded files aren't added anyway); the commit check backs it up.
- Worked in a worktree (`~/.config/dotfiles-local-ai-config-guard`) because the main worktree is
  live config and sits on `fix/bootstrap-zsh-plugins-aws-config`.

## Gotchas
- `git rev-parse --abbrev-ref origin/HEAD` prints the arg to stdout on failure; use
  `git symbolic-ref --quiet --short refs/remotes/origin/HEAD`.
- check.sh's later session-handoff test needs `$repo` to have no tracked CLAUDE.md, so the new
  test resets its commit.

## Key files
- `ai/claude/hooks/git-guard.py` (`repo_has`, `agent_config_problems`), `ai/AGENTS.md`, `scripts/check.sh`
