# Global preferences for AI coding assistants

Shared by every assistant (Claude Code, Copilot CLI, ...) via dotfiles `ai/AGENTS.md`.

## Python environments
- I use **pyenv virtualenvs** (pyenv-virtualenv), not `python -m venv` / `.venv` directories.
- Create with `pyenv virtualenv <python-version> <env-name>` and pin per project with
  `pyenv local <env-name>` (writes `.python-version`). Install packages only into the active
  pyenv virtualenv, never into the system Python.
- Check what's available with `pyenv versions` / `pyenv virtualenvs` before creating a new one.

## Learning from corrections
I don't want to repeat myself. When I correct, redirect, or state a preference about how you work
(not a one-off task detail):
1. Check `~/.config/dotfiles/ai/corrections.local.md` and the rules in this file and the project's
   instructions for the same or a similar correction.
2. Append it to that log: `- YYYY-MM-DD | <project or global> | <correction> | <status>`.
3. If it's the **second time** (same or similar meaning, even if worded differently), or it restates
   a rule you broke, **ask me** whether to codify it, and propose where:
   - global rule here in `ai/AGENTS.md` (applies to every assistant and project),
   - project rule in the project's `CLAUDE.md`/`AGENTS.md`,
   - a hook (e.g. `ai/claude/hooks/`) when a written rule already exists and was still broken,
     or the behaviour is mechanical enough to check automatically.
4. Update the entry's status (`codified: <where>`, or `declined` — then don't ask about it again).
Don't ask about things already codified unless they were broken; then propose enforcing them.

## Git branches
- **Never commit to, push to, merge into, or rebase `main` (or `master`) directly.** Before changing
  any tracked file, create a branch from an up-to-date `main` (`git switch main && git pull --rebase`,
  then `git switch -c <branch>`). Changes reach `main` only through a pull/merge request.
- Branch names are `<type>/<short-description>`, lowercase kebab-case, relevant to the change:
  `feat/room-creation`, `fix/vote-race-condition`, `docs/readme-setup`.
  Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `ci`, `perf`, `build`, `style`,
  `revert`. An optional ticket id may lead the description: `fix/proj-123-null-room-code`.
- If a repository documents its own branch naming or update strategy (CONTRIBUTING, README,
  AGENTS.md/CLAUDE.md), follow the repository. A repo can set its own branch regex with
  `git config ai.branchPattern '<regex>'`.

## Keeping branches up to date
- Rebase, don't merge: `git fetch && git rebase origin/main` (or `git pull --rebase`) unless the
  repository's protocol says to merge.
- After rebasing a branch that was already pushed, update it with `git push --force-with-lease`
  (never plain `--force`), and only on your own feature branch.
- Never rewrite history on `main` or on branches other people are working on.

## Git commits
- Never add Claude or Claude Code as an author or co-author (no `Co-Authored-By` trailer, no
  "Generated with Claude Code" line) in commit messages or PR descriptions.
- Commit messages are short (subject ≤72 characters after the prefix), descriptive, and
  **all lowercase**, including the body.
- Prefix the message with the branch name and a colon: `feat/room-creation: add create room handler`.
- One-line subject; add a body only when the reason for the change isn't obvious.
