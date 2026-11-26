#!/usr/bin/env python3
"""PreToolUse hook (Bash): block team-facing GitHub text until the voice skill is loaded.

Anything written for the team (issues, comments, PRs, reviews) is in the user's voice
(`ai/skills/voice`). This blocks `gh` commands that post or edit that text unless the session transcript shows
the `voice` skill was loaded, either through the Skill tool or by the user typing `/voice`.

Gated:
- `gh issue create|comment`, `gh pr create|comment`: always (they always post text).
- `gh issue|pr edit|close|review|merge|reopen`: only with a body, title or comment flag.
- `gh api`: only with a `body=` or `title=` field, or `--input`.

Exit 2 blocks the command and tells the assistant what to do. Anything this script can't parse,
or a missing transcript, is allowed through rather than blocked.
"""

from __future__ import annotations

import json
import re
import shlex
import sys
from pathlib import Path

SEPARATORS = {"&&", "||", ";", "|", "&"}
ALWAYS = {("issue", "create"), ("issue", "comment"), ("pr", "create"), ("pr", "comment")}
WITH_TEXT = {"edit", "close", "review", "merge", "reopen"}
TEXT_FLAGS = re.compile(
    r"^(-b|-t|-c|-F|--body|--body-file|--title|--comment|--subject)(=|$)"
)
API_TEXT = re.compile(r"^(body|title)=")
LOADED = re.compile(
    r'"name"\s*:\s*"Skill"\s*,\s*"input"\s*:\s*\{\s*"skill"\s*:\s*"voice"'
    r"|<command-name>/voice</command-name>"
)
MESSAGE = (
    "team-facing GitHub text rejected: load the voice skill first (Skill tool, skill \"voice\"), "
    "draft the text with the technical register, then run this command again. "
    "Everything posted to GitHub is written in the user's voice."
)


def segments(command: str) -> list[list[str]]:
    """Split a shell command into simple commands (token lists) on &&, ||, ;, |."""
    lexer = shlex.shlex(command, posix=True, punctuation_chars=True)
    lexer.whitespace_split = True
    parts, current = [], []
    for token in lexer:
        if token in SEPARATORS:
            parts.append(current)
            current = []
        else:
            current.append(token)
    parts.append(current)
    return [p for p in parts if p]


def posts_text(tokens: list[str]) -> bool:
    """True if this simple command is a gh call that posts or edits team-facing text."""
    if "gh" not in tokens:
        return False
    rest = tokens[tokens.index("gh") + 1 :]
    words = [t for t in rest if not t.startswith("-")]
    if not words:
        return False
    if words[0] == "api":
        return any(API_TEXT.match(t) for t in rest) or "--input" in rest
    if len(words) < 2 or words[0] not in {"issue", "pr"}:
        return False
    if (words[0], words[1]) in ALWAYS:
        return True
    return words[1] in WITH_TEXT and any(TEXT_FLAGS.match(t) for t in rest)


def voice_loaded(transcript: str) -> bool:
    """True if the session transcript shows the voice skill was loaded (missing file: True)."""
    path = Path(transcript).expanduser()
    if not transcript or not path.is_file():
        return True
    with path.open(errors="replace") as handle:
        return any(LOADED.search(line) for line in handle)


def main() -> int:
    payload = json.load(sys.stdin)
    raw = payload.get("tool_input", {}).get("command", "")
    if "gh" not in raw:
        return 0
    try:
        parsed = segments(raw)
    except ValueError:
        return 0
    if not any(posts_text(tokens) for tokens in parsed):
        return 0
    if voice_loaded(payload.get("transcript_path", "")):
        return 0
    print(MESSAGE, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
