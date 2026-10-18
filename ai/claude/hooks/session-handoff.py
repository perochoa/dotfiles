#!/usr/bin/env python3
"""SessionStart hook: load the handoff doc for the current branch (see "Session handoffs" in
ai/AGENTS.md) so a fresh, cleared, resumed or compacted session starts with the context.

- Repo tracks AGENTS.md or CLAUDE.md: docs live in `<worktree>/.handoff/` and are committed.
- Otherwise: docs live in `<main worktree>/.handoff/`, and `/.handoff/` is added to the repo's
  shared `info/exclude` so they're never committed.

Prints context for the assistant on stdout (exit 0). Silent outside git repos; never blocks.
"""

import json
import subprocess
import sys
from pathlib import Path

DIR_NAME = ".handoff"
EXCLUDE_LINE = f"/{DIR_NAME}/"
AGENT_FILES = ("AGENTS.md", "CLAUDE.md", ".claude/CLAUDE.md")
MAX_DOC_CHARS = 8000
MAX_LISTED = 15


def git(cwd: Path, *args: str) -> str:
    result = subprocess.run(["git", *args], cwd=cwd, capture_output=True, text=True, timeout=5)
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip())
    return result.stdout.strip()


def main_worktree(cwd: Path) -> Path:
    for line in git(cwd, "worktree", "list", "--porcelain").splitlines():
        if line.startswith("worktree "):
            return Path(line.removeprefix("worktree "))
    return Path(git(cwd, "rev-parse", "--show-toplevel"))


def ensure_excluded(cwd: Path) -> None:
    common = Path(git(cwd, "rev-parse", "--path-format=absolute", "--git-common-dir"))
    exclude = common / "info" / "exclude"
    text = exclude.read_text() if exclude.is_file() else ""
    if EXCLUDE_LINE in text.splitlines():
        return
    exclude.parent.mkdir(parents=True, exist_ok=True)
    prefix = "" if not text or text.endswith("\n") else "\n"
    exclude.write_text(f"{text}{prefix}# local ai session handoffs (ai/AGENTS.md)\n{EXCLUDE_LINE}\n")


def main() -> int:
    data = json.load(sys.stdin)
    cwd = Path(data.get("cwd") or ".")
    try:
        top = Path(git(cwd, "rev-parse", "--show-toplevel"))
    except (RuntimeError, OSError, subprocess.SubprocessError):
        return 0  # not a git repo (or bare / no git)

    shared = bool(git(top, "ls-files", "--", *AGENT_FILES))
    if shared:
        root, mode = top, "committed (repo tracks AGENTS.md/CLAUDE.md): commit .handoff/ on the feature branch"
    else:
        root = main_worktree(top)
        ensure_excluded(top)
        mode = (
            "local only (no tracked AGENTS.md/CLAUDE.md): never commit .handoff/, and don't create "
            "an AGENTS.md or CLAUDE.md; /.handoff/ is in .git/info/exclude"
        )

    branch = git(top, "branch", "--show-current") or "detached"
    handoff_dir = root / DIR_NAME
    doc = handoff_dir / f"{branch.replace('/', '-')}.md"

    lines = [
        "[session-handoff] Follow 'Session handoffs' in ~/.claude/CLAUDE.md.",
        f"Mode: {mode}.",
        f"Branch: {branch}. Handoff doc: {doc}",
    ]
    if branch in ("main", "master", "detached"):
        lines.append(
            "Not on a feature branch: reuse the doc for the topic you work on, or create one named "
            "after the branch you create."
        )

    others = [p for p in handoff_dir.glob("*.md") if p != doc]
    others.sort(key=lambda p: p.stat().st_mtime, reverse=True)
    if others:
        lines.append("Other handoff docs (newest first; read any relevant to the task):")
        lines += [f"- {p}" for p in others[:MAX_LISTED]]

    if doc.is_file():
        text = doc.read_text(errors="replace")
        if len(text) > MAX_DOC_CHARS:
            text = text[:MAX_DOC_CHARS] + f"\n[... truncated; read {doc} for the rest]"
        lines += ["Current handoff doc:", "<handoff>", text.rstrip(), "</handoff>",
                  "Keep it current as you work; I may clear this session without warning."]
    else:
        lines.append("No doc for this branch yet: create it once the task is clear, then keep it current.")

    print("\n".join(lines))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as error:  # a broken hook must never block a session
        print(f"[session-handoff] hook error: {error}", file=sys.stderr)
        sys.exit(0)
