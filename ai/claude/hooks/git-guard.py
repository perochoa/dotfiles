#!/usr/bin/env python3
"""PreToolUse hook (Bash): enforce the git rules in ai/AGENTS.md before a git command runs.

- main/master is never changed directly: no commit, merge, rebase, cherry-pick, revert or am while
  on it, and no push to it.
- New branches are named `<type>/<kebab-description>` (or the repo's `git config ai.branchPattern`).
- No plain force-push (`--force-with-lease` is fine on feature branches).
- Commit messages: no AI attribution, all lowercase, `<branch>: ` prefix, short subject.
- AI assistant config (CLAUDE.md, CLAUDE.local.md, AGENTS.md, .claude/) is never added or
  committed unless the repo already has that file (on the remote's default branch, or in HEAD when
  there's no remote), or `git config ai.shareAgentConfig true` opts the repo in.

Exit 2 blocks the command and shows the reasons to the assistant. Anything this script can't
parse is allowed through rather than blocked.
"""

from __future__ import annotations

import json
import re
import shlex
import subprocess
import sys
from pathlib import Path

PROTECTED = {"main", "master"}
MAX_SUBJECT = 72
BRANCH_TYPES = "feat|fix|docs|refactor|test|chore|ci|perf|build|style|revert"
DEFAULT_BRANCH_PATTERN = rf"^({BRANCH_TYPES})/[a-z0-9]+(-[a-z0-9]+)*$"
MAIN_CHANGING = {"commit", "merge", "rebase", "cherry-pick", "revert", "am"}
LONG_WITH_VALUE = {"--message", "--file", "--reuse-message", "--reedit-message", "--template"}
ATTRIBUTION = re.compile(
    r"co-authored-by|generated (with|by)\b.*\b(claude|copilot|ai)\b|\bclaude code\b|noreply@anthropic",
    re.IGNORECASE,
)
HEREDOC = re.compile(r"<<-?\s*['\"]?(\w+)['\"]?[^\n]*\n(.*?)\n\s*\1\b", re.DOTALL)
SEPARATORS = {"&&", "||", ";", "|", "&"}
NO_BRANCH_FIX = "create a branch first: git switch -c <type>/<description>"
AGENT_CONFIG = re.compile(r"(^|/)(CLAUDE(\.local)?\.md|AGENTS\.md)$|(^|/)\.claude(/|$)")
AGENT_CONFIG_FIX = (
    "is local AI assistant config the repo doesn't have yet; keep it out of git by listing it in "
    "$(git rev-parse --git-common-dir)/info/exclude (or `git config ai.shareAgentConfig true` "
    "if the user asked to share it)."
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


def git(repo: Path, *args: str) -> str:
    """Run a read-only git query in repo and return stripped stdout ('' on failure)."""
    result = subprocess.run(
        ["git", "-C", str(repo), *args], capture_output=True, text=True, check=False
    )
    return result.stdout.strip()


def current_branch(repo: Path) -> str:
    """Return the checked-out branch, or the branch being rebased while HEAD is detached."""
    branch = git(repo, "branch", "--show-current")
    if branch:
        return branch
    for state in ("rebase-merge", "rebase-apply"):
        path = git(repo, "rev-parse", "--path-format=absolute", "--git-path", f"{state}/head-name")
        head = Path(path) if path else None
        if head and head.is_file():
            return head.read_text().strip().removeprefix("refs/heads/")
    return ""


def split_git(tokens: list[str], cwd: Path) -> tuple[Path, str, list[str]] | None:
    """Return (repo dir, subcommand, args) for a git invocation, or None if it isn't one."""
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
    if i >= len(tokens):
        return None
    return repo, tokens[i], tokens[i + 1 :]


def expand(value: str, raw: str) -> str:
    """Resolve a `$(cat <<'EOF' ... EOF)` message to its heredoc body."""
    if "<<" in value:
        match = HEREDOC.search(value) or HEREDOC.search(raw)
        if match:
            return match.group(2)
    return value


def commit_options(args: list[str]) -> list[tuple[str, str]]:
    """Return the (-m|-F, value) options of a `git commit`, reading short flags the way git does.

    Short flags can be bundled (`-qm msg`, `-aF -`, `-qmmsg`): the first one that takes a value
    gets the rest of the bundle, or the next argument.
    """
    found, i = [], 0
    while i < len(args):
        arg = args[i]
        i += 1
        if arg == "--":
            break
        if arg.startswith("--"):
            name, eq, value = arg.partition("=")
            if name in LONG_WITH_VALUE and not eq and i < len(args):
                value, i = args[i], i + 1
            if name in ("--message", "--file"):
                found.append(("-m" if name == "--message" else "-F", value))
            continue
        if not arg.startswith("-") or arg == "-":
            continue
        for k, flag in enumerate(arg[1:], 1):
            if flag in "mFcCt":  # flags that take a value
                value = arg[k + 1 :]
                if not value and i < len(args):
                    value, i = args[i], i + 1
                if flag in "mF":
                    found.append((f"-{flag}", value))
                break
            if flag in "Su":  # optional value, attached only
                break
    return found


def commit_message(args: list[str], raw: str, repo: Path) -> str | None:
    """Return the message a `git commit` would use, or None if it isn't given inline or by file."""
    messages = []
    for flag, value in commit_options(args):
        if flag == "-m":
            messages.append(expand(value, raw))
        elif value == "-":
            match = HEREDOC.search(raw)
            messages.append(match.group(2) if match else None)
        else:
            path = Path(value) if Path(value).is_absolute() else repo / value
            messages.append(path.read_text() if path.is_file() else None)
    if not messages or None in messages:
        return None
    return "\n\n".join(m.strip() for m in messages)


def message_problems(message: str, branch: str) -> list[str]:
    """List every commit-message rule the message breaks."""
    found = []
    subject = message.strip().splitlines()[0] if message.strip() else ""
    if ATTRIBUTION.search(message):
        found.append("remove AI attribution (Co-Authored-By, 'Generated with ...'); never credit an AI.")
    if message != message.lower():
        found.append("the whole commit message must be lowercase.")
    description = subject
    if branch:
        prefix = f"{branch}: "
        if not subject.startswith(prefix):
            found.append(f"the subject must start with '{prefix}'.")
        else:
            description = subject[len(prefix) :]
    if not description.strip():
        found.append("the subject needs a short description.")
    elif len(description) > MAX_SUBJECT:
        found.append(f"keep the subject short: {len(description)} chars, limit {MAX_SUBJECT}.")
    return found


def branch_problems(name: str, repo: Path) -> list[str]:
    """Check a new branch name against the repo's pattern or the default convention."""
    pattern = git(repo, "config", "--get", "ai.branchPattern") or DEFAULT_BRANCH_PATTERN
    if re.fullmatch(pattern, name):
        return []
    return [
        f"branch name '{name}' doesn't follow the convention ({pattern}); "
        "use <type>/<short-kebab-description>, e.g. feat/room-creation or fix/vote-race."
    ]


def new_branch_name(sub: str, args: list[str]) -> str | None:
    """Return the branch a switch/checkout/branch command would create or rename to."""
    create = {"switch": {"-c", "-C", "--create", "--force-create"}, "checkout": {"-b", "-B"}}
    if sub in create:
        for j, arg in enumerate(args[:-1]):
            if arg in create[sub]:
                return args[j + 1]
        return None
    if sub == "branch":
        positional = [a for a in args if not a.startswith("-")]
        if any(a in ("-m", "-M", "--move") for a in args) and positional:
            return positional[-1]
        listing = {"-d", "-D", "--delete", "-l", "--list", "-a", "-r", "-v", "-vv", "--show-current",
                   "--contains", "--merged", "--no-merged", "-u", "--set-upstream-to",
                   "--unset-upstream", "--edit-description", "-c", "-C", "--copy"}
        if positional and not listing.intersection(args):
            return positional[0]
    return None


def push_problems(args: list[str], branch: str) -> list[str]:
    """Block plain force-pushes and any push that would update a protected branch."""
    found = []
    if "--force" in args or "-f" in args:
        found.append("plain force-push is not allowed; use --force-with-lease on your own branch.")
    if "--all" in args or "--mirror" in args:
        found.append("don't push all branches (--all/--mirror); push only your feature branch.")
    positional = [a for a in args if not a.startswith("-")]
    refspecs = positional[1:]
    if not refspecs and branch in PROTECTED:
        found.append(f"you're on '{branch}'; never push it directly. {NO_BRANCH_FIX}")
    for spec in refspecs:
        if spec.startswith("+"):
            found.append(f"'{spec}' is a force-push; use --force-with-lease instead.")
        dest = spec.lstrip("+").split(":")[-1].removeprefix("refs/heads/")
        if dest == "HEAD":
            dest = branch
        if dest in PROTECTED:
            found.append(f"never push to '{dest}' directly; open a pull request from a branch.")
    return found


def repo_has(repo: Path, path: str) -> bool:
    """True if the remote's default branch (or HEAD, with no remote) already tracks path."""
    base = git(repo, "symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD")
    if not base:
        for candidate in ("origin/main", "origin/master"):
            if git(repo, "rev-parse", "--verify", "--quiet", candidate):
                base = candidate
                break
    return bool(git(repo, "ls-tree", "-r", "--name-only", base or "HEAD", "--", path))


def agent_config_problems(sub: str, args: list[str], repo: Path) -> list[str]:
    """Block adding or committing AI assistant config the repo doesn't already have."""
    if sub not in ("add", "commit") or git(repo, "config", "--bool", "ai.shareAgentConfig") == "true":
        return []
    top = git(repo, "rev-parse", "--show-toplevel")
    if not top:
        return []
    if sub == "add":
        paths = []
        for arg in (a for a in args if not a.startswith("-")):
            try:
                paths.append((repo / arg).resolve().relative_to(Path(top).resolve()).as_posix())
            except ValueError:
                continue
    else:
        paths = git(repo, "diff", "--cached", "--name-only", "--diff-filter=d").splitlines()
        if any(a == "--all" or re.fullmatch(r"-[a-zA-Z]*a[a-zA-Z]*", a) for a in args):
            paths += git(repo, "diff", "--name-only", "--diff-filter=d").splitlines()
    return [
        f"'{path}' {AGENT_CONFIG_FIX}"
        for path in dict.fromkeys(paths)
        if AGENT_CONFIG.search(path) and not repo_has(repo, path)
    ]


def check(sub: str, args: list[str], raw: str, repo: Path) -> list[str]:
    """Return every rule this git invocation breaks."""
    branch = current_branch(repo)
    found = []
    if sub in MAIN_CHANGING and branch in PROTECTED:
        if not (sub == "merge" and "--ff-only" in args):  # fast-forwarding to the remote is fine
            found.append(f"never {sub} on '{branch}' directly. {NO_BRANCH_FIX}")
    if sub == "commit" and branch not in PROTECTED:
        message = commit_message(args, raw, repo)
        if message is not None:
            found += message_problems(message, branch)
    if sub == "push":
        found += push_problems(args, branch)
    name = new_branch_name(sub, args)
    if name:
        found += branch_problems(name, repo)
    found += agent_config_problems(sub, args, repo)
    return found


def main() -> int:
    payload = json.load(sys.stdin)
    raw = payload.get("tool_input", {}).get("command", "")
    if "git" not in raw:
        return 0
    cwd = Path(payload.get("cwd") or ".")
    try:
        parsed = segments(raw)
    except ValueError:
        return 0

    found = []
    for tokens in parsed:
        if tokens[0] == "cd" and len(tokens) > 1:  # track `cd dir && git ...`
            cwd = (cwd / Path(tokens[1]).expanduser()).resolve()
            continue
        invocation = split_git(tokens, cwd)
        if invocation:
            repo, sub, args = invocation
            found += check(sub, args, raw, repo)
    if found:
        print("git command rejected (see ~/.claude/CLAUDE.md, Git sections):", file=sys.stderr)
        for item in dict.fromkeys(found):
            print(f"  - {item}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
