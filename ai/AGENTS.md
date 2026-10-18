# Global preferences for AI coding assistants

Shared by every assistant (Claude Code, Copilot CLI, ...) via dotfiles `ai/AGENTS.md`.

## Python environments
- I use **pyenv virtualenvs** (pyenv-virtualenv), not `python -m venv` / `.venv` directories.
- Create with `pyenv virtualenv <python-version> <env-name>` and pin per project with
  `pyenv local <env-name>` (writes `.python-version`). Install packages only into the active
  pyenv virtualenv, never into the system Python.
- Check what's available with `pyenv versions` / `pyenv virtualenvs` before creating a new one.

## Git commits
- Never add Claude or Claude Code as an author or co-author (no `Co-Authored-By` trailer, no
  "Generated with Claude Code" line) in commit messages or PR descriptions.
- Commit messages are short, descriptive, and **all lowercase**.
- On any branch other than `main`, prefix the message with the branch name and a colon:
  `feat/room-creation: add create room handler`. On `main`, no prefix: `add aws connectivity check`.
- One-line subject; add a body only when the reason for the change isn't obvious (also lowercase).
