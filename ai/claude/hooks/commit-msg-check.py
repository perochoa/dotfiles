#!/usr/bin/env python3
"""PreToolUse hook (Bash): enforce commit message rules from ai/AGENTS.md before `git commit` runs.

Rules: no AI author/co-author attribution, all lowercase, `<branch>: ` prefix when not on main,
and a short subject. Exit 2 blocks the command and shows the reasons to the assistant.
Anything this script can't parse is allowed through rather than blocked.
"""

import json
import re
import shlex
import subprocess
import sys
from pathlib import Path

UNPREFIXED_BRANCHES = {"main", "master"}
MAX_SUBJECT = 72
ATTRIBUTION = re.compile(
    r"co-authored-by|generated (with|by)\b.*\b(claude|copilot|ai)\b|\bclaude code\b|noreply@anthropic",
    re.IGNORECASE,
)
HEREDOC = re.compile(r"<<-?\s*['\"]?(\w+)['\"]?[^\n]*\n(.*?)\n\s*\1\b", re.DOTALL)
SEPARATORS = {"&&", "||", ";", "|", "&"}


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


def expand(value: str, raw: str) -> str:
    """Resolve a `$(cat <<'EOF' ... EOF)` message to its heredoc body."""
    if "<<" in value:
        match = HEREDOC.search(value) or HEREDOC.search(raw)
        if match:
            return match.group(2)
    return value


def parse_commit(tokens: list[str], raw: str, cwd: Path) -> tuple[Path, str | None] | None:
    """Return (repo dir, message) for a `git ... commit` token list, or None if it isn't one."""
    if not tokens or Path(tokens[0]).name != "git":
        return None
    i, repo = 1, cwd
    while i < len(tokens) and tokens[i].startswith("-"):  # global options before the subcommand
        if tokens[i] == "-C" and i + 1 < len(tokens):
            repo = (cwd / tokens[i + 1]).resolve()
            i += 2
        elif tokens[i] == "-c":
            i += 2
        else:
            i += 1
    if i >= len(tokens) or tokens[i] != "commit":
        return None

    messages, args = [], tokens[i + 1 :]
    for j, arg in enumerate(args):
        nxt = args[j + 1] if j + 1 < len(args) else None
        if arg in ("-m", "--message") and nxt is not None:
            messages.append(expand(nxt, raw))
        elif arg.startswith("--message="):
            messages.append(expand(arg.split("=", 1)[1], raw))
        elif arg.startswith("-m") and len(arg) > 2 and not arg.startswith("--"):
            messages.append(expand(arg[2:], raw))
        elif arg in ("-F", "--file") and nxt is not None:
            if nxt == "-":
                match = HEREDOC.search(raw)
                messages.append(match.group(2) if match else None)
            else:
                path = Path(nxt) if Path(nxt).is_absolute() else repo / nxt
                messages.append(path.read_text() if path.is_file() else None)
    if not messages or None in messages:
        return repo, None
    return repo, "\n\n".join(m.strip() for m in messages)


def problems(message: str, branch: str) -> list[str]:
    """List every rule the message breaks."""
    found = []
    lines = [line for line in message.strip().splitlines()]
    subject = lines[0] if lines else ""
    if ATTRIBUTION.search(message):
        found.append("remove AI attribution (Co-Authored-By, 'Generated with ...'); never credit an AI.")
    if message != message.lower():
        found.append("the whole message must be lowercase.")
    description = subject
    if branch and branch not in UNPREFIXED_BRANCHES:
        prefix = f"{branch}: "
        if not subject.startswith(prefix):
            found.append(f"on branch '{branch}' the subject must start with '{prefix}'.")
        else:
            description = subject[len(prefix) :]
    if not description.strip():
        found.append("the subject needs a short description.")
    elif len(description) > MAX_SUBJECT:
        found.append(f"keep the subject short: {len(description)} chars, limit {MAX_SUBJECT}.")
    return found


def main() -> int:
    payload = json.load(sys.stdin)
    raw = payload.get("tool_input", {}).get("command", "")
    if "commit" not in raw:
        return 0
    cwd = Path(payload.get("cwd") or ".")
    try:
        parsed = segments(raw)
    except ValueError:
        return 0

    for tokens in parsed:
        if tokens[0] == "cd" and len(tokens) > 1:  # track `cd dir && git commit ...`
            cwd = (cwd / Path(tokens[1]).expanduser()).resolve()
            continue
        commit = parse_commit(tokens, raw, cwd)
        if not commit or commit[1] is None:
            continue
        repo, message = commit
        branch = subprocess.run(
            ["git", "-C", str(repo), "branch", "--show-current"],
            capture_output=True, text=True, check=False,
        ).stdout.strip()
        found = problems(message, branch)
        if found:
            print("commit message rejected (see ~/.claude/CLAUDE.md, Git commits):", file=sys.stderr)
            for item in found:
                print(f"  - {item}", file=sys.stderr)
            return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
