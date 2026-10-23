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

## Session handoffs
I clear sessions often (new feature, new component, or a session that ran long), so in every git
repository keep a handoff document that lets the next session pick up without me re-explaining.
- **One doc per feature/branch**: `.handoff/<branch>.md`, with `/` in the branch name replaced by `-`
  (`feat/room-creation` → `.handoff/feat-room-creation.md`). On `main`, reuse the doc for the topic
  you're working on, or create one named after the branch you're about to create.
- **Where it lives depends on the repo**:
  - Repo tracks an `AGENTS.md` or `CLAUDE.md` (root or `.claude/CLAUDE.md`): `.handoff/` sits in the
    worktree and is committed on the feature branch with the work it describes.
  - Repo has neither: the handoffs are local only. **Don't commit or push an `AGENTS.md` or
    `CLAUDE.md`** for this (see "AI assistant config" below). Keep `.handoff/` in the main
    worktree, so it survives removing other worktrees, and list `/.handoff/` in the repo's
    `$(git rev-parse --git-common-dir)/info/exclude`, never in `.gitignore`. Never `git add -f` it.
- **Start of a session**: read the doc for the current branch, and any others relevant to the task,
  before doing anything. Claude Code's `session-handoff.py` hook prints the path, the mode, and the
  doc; other assistants check `.handoff/` themselves.
- **Keep it current**: update it after each meaningful step (a decision made, a task done, a
  blocker found), before committing, and before you stop. Don't leave it for the end of the
  session: I may clear it without warning.
- **Contents**: short and rewritten in place, not an append-only log. Remove anything that's no
  longer true. Sections:
  `Goal`, `Status` (done / in progress / next, as checklists), `Decisions` (with the why),
  `Gotchas` (dead ends, surprises, commands that matter), `Key files`, `Open questions`.
  Write facts the code and git history don't already show. No secrets or credentials.
- When the work is merged or abandoned, set `Status` to done or abandoned. Delete the doc once
  it stops being useful.

## AI assistant config
- `CLAUDE.md`, `CLAUDE.local.md`, `AGENTS.md` and `.claude/` are local to me **unless the repository
  already has them on its remote** (I'm often the only one on a team using these tools).
- When you create one the repo doesn't have (e.g. via `/init`), list it in
  `$(git rev-parse --git-common-dir)/info/exclude` straight away, never in `.gitignore`. Don't
  offer to commit it, and never `git add -f` it.
- If the repo already tracks them, they're shared: edit and commit them like any other file.
- `git-guard.py` enforces this. A repo where I asked to share them opts out with
  `git config ai.shareAgentConfig true`.

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
- Commit as you go: make each commit when its logical piece of work is finished and checked, in
  the order the work was done, instead of batching every commit at the end of a task. That way
  the history is in chronological order and the commits are naturally spread out in time.
- Commit timestamps must be real. Never set fake author or committer dates (`--date`,
  `GIT_AUTHOR_DATE`, `GIT_COMMITTER_DATE`, or rewriting dates in a rebase).
