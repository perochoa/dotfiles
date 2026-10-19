#!/usr/bin/env python3
"""Hook: `architecture-implementer` only applies audits that `architecture-auditor` produced.

One script for every event; argv[1] (set in agent frontmatter) names the agent when the payload
has no `agent_type`, e.g. in a `claude --agent <name>` session.

- Stop/SubagentStop of the auditor: record its report in ~/.claude/audits/<id>.md (+ <id>.json),
  but only when it has the four required sections. id = first 12 hex of the report's sha256.
- PreToolUse Agent/Task for the implementer: the prompt must be exactly
  `audit: <id|latest>` and `steps: <all|1,3|2-4>`, naming an audit recorded for this repo. The
  prompt is replaced by the recorded report, and a per-repo lease (base commit, files already
  dirty) is stored in ~/.claude/audits/leases/.
- PreToolUse from the implementer: no lease, no Bash/Edit/Write. Edits are limited to the
  files the report cites.
- Stop/SubagentStop of the implementer: everything changed since the lease must be cited in the
  report, or the stop is blocked until it is reverted. A clean stop releases the lease.
- PreToolUse from anyone: no writes into ~/.claude/audits (only this hook writes there).

Decisions are printed as JSON on stdout. Errors deny only the implementer's own calls; any other
error lets the call through.
"""

from __future__ import annotations

import fnmatch
import hashlib
import json
import re
import shlex
import subprocess
import sys
import time
from pathlib import Path

AUDITOR = "architecture-auditor"
IMPLEMENTER = "architecture-implementer"
AUDITS = Path.home() / ".claude" / "audits"
LEASES = AUDITS / "leases"
LEASE_TTL = 6 * 3600
MAX_STOP_BLOCKS = 3
SECTIONS = (
    "Executive Summary",
    "Best Practices Audit",
    "Refactoring & Simplification Roadmap",
    "Before-and-After",
)
EDIT_TOOLS = {"Edit", "Write", "MultiEdit", "NotebookEdit"}
STEP = r"\d+(?:-\d+)?"
LAUNCH = re.compile(
    rf"\A\s*audit:\s*(\w+)\s*\n\s*steps:\s*(all|{STEP}(?:\s*,\s*{STEP})*)\s*\Z", re.IGNORECASE
)
BACKTICKED = re.compile(r"`([^`\n]+)`")
BARE_PATH = re.compile(r"(?<![\w/.`-])(?:[\w.-]+/)+[\w.-]+\.\w+(?::\d+(?:-\d+)?)?")
LINE_SUFFIX = re.compile(r":\d+(?:-\d+)?$")
BRACES = re.compile(r"\{([^{}]*)\}")
# A shell command writes the registry if it redirects into it or a writing command names it.
REGISTRY_WRITERS = r"cd|rm|mv|cp|tee|ln|touch|truncate|dd|install|rsync|chmod|mkdir|sed|perl"
HOME_FORMS = rf"(?:~|\$HOME|\$\{{HOME\}}|{re.escape(str(Path.home()))})"
REGISTRY_WRITE = re.compile(rf"(?:>>?|\b(?:{REGISTRY_WRITERS})\b[^\n;&|]*?)\s*['\"]?{HOME_FORMS}/\.claude/audits\b")
STOP_EXEMPT = (".handoff/",)
USAGE = f"launch {IMPLEMENTER} with a prompt of exactly two lines:\n  audit: <id or latest>\n  steps: <all, or e.g. 1,3,5-7>"


def git(repo: Path, *args: str) -> str:
    result = subprocess.run(
        ["git", "-C", str(repo), *args], capture_output=True, text=True, check=False, timeout=10
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or f"git {args[0]} failed")
    return result.stdout.strip()


def toplevel(path: Path) -> Path | None:
    while not path.exists() and path != path.parent:  # a file about to be created
        path = path.parent
    try:
        return Path(git(path if path.is_dir() else path.parent, "rev-parse", "--show-toplevel"))
    except (RuntimeError, OSError, subprocess.SubprocessError):
        return None


def digest(text: str) -> str:
    return hashlib.sha256(text.encode()).hexdigest()


def decide(decision: str, reason: str, **extra) -> dict:
    return {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": decision,
            "permissionDecisionReason": reason,
            **extra,
        }
    }


def deny(reason: str) -> dict:
    return decide("deny", reason)


# Registry -----------------------------------------------------------------------------------


def has_sections(report: str) -> bool:
    return all(re.search(rf"^#+ .*{re.escape(s)}", report, re.MULTILINE) for s in SECTIONS)


def handback(block: dict) -> str:
    """The report a subagent passed to SubagentHandback, which is then its final output."""
    if block.get("type") == "tool_use" and block.get("name") == "SubagentHandback":
        return str((block.get("input") or {}).get("message") or "")
    return ""


def last_text(transcript: str) -> str:
    """Last assistant text or hand-back report in a transcript."""
    text = ""
    path = Path(transcript)
    if not path.is_file():
        return text
    for line in path.read_text().splitlines():
        try:
            entry = json.loads(line)
        except ValueError:
            continue
        if entry.get("type") != "assistant":
            continue
        content = entry.get("message", {}).get("content", [])
        blocks = [c for c in content if isinstance(c, dict)]
        parts = [c.get("text", "") if c.get("type") == "text" else handback(c) for c in blocks]
        if any(parts):
            text = "\n".join(p for p in parts if p)
    return text


def record(payload: dict) -> None:
    report = (payload.get("last_assistant_message") or "").strip()
    if not has_sections(report):  # e.g. the report went out through SubagentHandback
        # On SubagentStop, transcript_path is the parent's; the auditor's own is agent_transcript_path.
        transcript = payload.get("agent_transcript_path") or payload.get("transcript_path") or ""
        report = last_text(transcript).strip()
    repo = toplevel(Path(payload.get("cwd") or "."))
    if not repo or not has_sections(report):
        return
    audit_id = digest(report)[:12]
    AUDITS.mkdir(parents=True, exist_ok=True)
    (AUDITS / f"{audit_id}.md").write_text(report + "\n")
    meta = {
        "id": audit_id,
        "repo": str(repo),
        "created": int(time.time()),
        "session_id": payload.get("session_id"),
        "agent_id": payload.get("agent_id"),
        "transcript": payload.get("agent_transcript_path") or payload.get("transcript_path"),
    }
    (AUDITS / f"{audit_id}.json").write_text(json.dumps(meta, indent=2) + "\n")


def audits_for(repo: Path) -> list[dict]:
    metas = []
    for path in AUDITS.glob("*.json"):
        meta = json.loads(path.read_text())
        if meta.get("repo") == str(repo):
            metas.append(meta)
    return sorted(metas, key=lambda m: m["created"], reverse=True)


def load_report(audit_id: str) -> str | None:
    """The recorded report, or None if it's missing or no longer matches its id."""
    path = AUDITS / f"{audit_id}.md"
    if not path.is_file():
        return None
    report = path.read_text().strip()
    return report if digest(report)[:12] == audit_id else None


def protect_registry(payload: dict) -> dict | None:
    tool, tool_input = payload.get("tool_name"), payload.get("tool_input") or {}
    if tool in EDIT_TOOLS:
        target = tool_input.get("file_path") or tool_input.get("notebook_path") or ""
        resolved = Path(target).expanduser().resolve()
        if resolved == AUDITS or AUDITS in resolved.parents:
            return deny(f"{AUDITS} is written only by the audit-gate hook; audits come from {AUDITOR}.")
    elif tool == "Bash":
        if REGISTRY_WRITE.search(tool_input.get("command", "")):
            return deny(f"{AUDITS} is read-only for tools; audits come from {AUDITOR}.")
    return None


# Leases -------------------------------------------------------------------------------------


def lease_path(repo: Path) -> Path:
    return LEASES / f"{digest(str(repo))[:16]}.json"


def active_lease(repo: Path) -> dict | None:
    path = lease_path(repo)
    if not path.is_file():
        return None
    lease = json.loads(path.read_text())
    return lease if time.time() - lease["created"] < LEASE_TTL else None


def changed_files(repo: Path, base: str | None) -> set[str]:
    if base:
        changed = git(repo, "diff", "--name-only", "--no-renames", base).splitlines()
    else:  # no commits yet
        changed = git(repo, "ls-files").splitlines()
    changed += git(repo, "ls-files", "--others", "--exclude-standard").splitlines()
    return {c for c in changed if c}


def launch(payload: dict) -> dict | None:
    tool_input = payload.get("tool_input") or {}
    if (tool_input.get("subagent_type") or tool_input.get("agent_type")) != IMPLEMENTER:
        return None
    repo = toplevel(Path(payload.get("cwd") or "."))
    if not repo:
        return deny(f"{IMPLEMENTER} only runs inside a git repository.")
    metas = audits_for(repo) if AUDITS.is_dir() else []
    known = "\n".join(f"  {m['id']}  {time.strftime('%Y-%m-%d %H:%M', time.localtime(m['created']))}" for m in metas[:10])
    known = f"recorded {AUDITOR} audits for {repo}:\n{known}" if known else f"no {AUDITOR} audit is recorded for {repo}; run {AUDITOR} first."

    match = LAUNCH.match(tool_input.get("prompt") or "")
    if not match:
        return deny(f"{IMPLEMENTER} only applies {AUDITOR} reports, so the prompt can't carry other instructions.\n{USAGE}\n{known}")
    audit_id, steps = match.group(1).lower(), match.group(2).replace(" ", "").lower()
    if audit_id == "latest":
        if not metas:
            return deny(known)
        audit_id = metas[0]["id"]
    elif audit_id not in {m["id"] for m in metas}:
        return deny(f"audit {audit_id} was not recorded from {AUDITOR} for this repo.\n{known}")
    report = load_report(audit_id)
    if report is None:
        return deny(f"audit {audit_id} is missing or was modified after {AUDITOR} produced it.")

    current = active_lease(repo)
    if current and current["audit"] != audit_id:
        return deny(f"{IMPLEMENTER} is already applying audit {current['audit']} in {repo}; wait for it to finish.")
    try:
        base = git(repo, "rev-parse", "HEAD")
    except RuntimeError:
        base = None
    lease = {
        "audit": audit_id,
        "steps": steps,
        "repo": str(repo),
        "base": base,
        "dirty": sorted(changed_files(repo, base)),
        "created": int(time.time()),
        "stop_blocks": 0,
    }
    LEASES.mkdir(parents=True, exist_ok=True)
    lease_path(repo).write_text(json.dumps(lease, indent=2) + "\n")

    prompt = (
        f"Apply roadmap steps `{steps}` of {AUDITOR} audit {audit_id} to the repository {repo}.\n"
        f"The report is the only source of changes; it is also saved at {AUDITS / (audit_id + '.md')}.\n"
        f"Files already modified before you started (leave them alone): {', '.join(lease['dirty']) or 'none'}.\n\n"
        f"<audit id=\"{audit_id}\">\n{report}\n</audit>"
    )
    reason = f"audit {audit_id} from {AUDITOR}, steps {steps}"
    return decide("allow", reason, updatedInput={**tool_input, "prompt": prompt})


# Scope --------------------------------------------------------------------------------------


def expand_braces(pattern: str) -> list[str]:
    match = BRACES.search(pattern)
    if not match:
        return [pattern]
    head, tail = pattern[: match.start()], pattern[match.end() :]
    return [p for alt in match.group(1).split(",") for p in expand_braces(head + alt + tail)]


def cited_paths(report: str, repo: Path) -> set[str]:
    """Paths, globs and `dir/` prefixes the report cites, relative to the repo."""
    tokens = [t for span in BACKTICKED.findall(report) for t in span.split()]
    tokens += BARE_PATH.findall(report)
    cited = set()
    for token in tokens:
        token = LINE_SUFFIX.sub("", token.strip(",.;:()[]'\""))
        if token.startswith(str(repo) + "/"):
            token = token[len(str(repo)) + 1 :]
        token = token.removeprefix("./")
        if not token or token.startswith(("-", "/", "~", "$", "http")) or "=" in token or ".." in token:
            continue
        if "/" not in token and "." not in token.strip("."):
            continue  # a word, not a file
        for path in expand_braces(token):
            glob_at = min((path.find(c) for c in "*?[" if c in path), default=-1)
            if glob_at != -1 and "/" not in path[:glob_at]:
                continue  # `*.py` and friends would allow nearly anything
            cited.add(path)
    return cited


def in_scope(rel: str, cited: set[str]) -> bool:
    for pattern in cited:
        if pattern.endswith("/"):
            if rel.startswith(pattern):
                return True
        elif "/" not in pattern:
            if Path(rel).name == pattern:
                return True
        elif rel == pattern or fnmatch.fnmatchcase(rel, pattern):
            return True
    return False


def scope(payload: dict) -> dict | None:
    tool, tool_input = payload.get("tool_name"), payload.get("tool_input") or {}
    if tool not in EDIT_TOOLS and tool != "Bash":
        return None
    cwd = Path(payload.get("cwd") or ".")
    target = None
    if tool in EDIT_TOOLS:
        raw = tool_input.get("file_path") or tool_input.get("notebook_path") or ""
        target = (cwd / Path(raw).expanduser()).resolve()
    repo = toplevel(target or cwd)
    lease = active_lease(repo) if repo else None
    if not lease:
        return deny(f"no active audit lease for this repository. {IMPLEMENTER} only works on {AUDITOR} reports and must be launched by the Agent tool ({USAGE.split(' with ', 1)[1]}).")
    if target is None:
        return None  # Bash: checked as a whole when the agent stops
    report = load_report(lease["audit"]) or ""
    rel = target.relative_to(repo).as_posix()
    if not in_scope(rel, cited_paths(report, repo)):
        return deny(f"{rel} is not cited in audit {lease['audit']}. Only change files the audit names; if a step needs this file, stop and say so in your report.")
    return None


def stop_check(payload: dict) -> dict | None:
    repo = toplevel(Path(payload.get("cwd") or "."))
    lease = active_lease(repo) if repo else None
    if not lease:
        return None
    report = load_report(lease["audit"]) or ""
    cited = cited_paths(report, repo)
    exempt = set(lease["dirty"])
    outside = sorted(
        f for f in changed_files(repo, lease["base"]) - exempt
        if not f.startswith(STOP_EXEMPT) and not in_scope(f, cited)
    )
    path = lease_path(repo)
    if not outside or lease["stop_blocks"] >= MAX_STOP_BLOCKS:
        path.unlink(missing_ok=True)
        return None
    lease["stop_blocks"] += 1
    path.write_text(json.dumps(lease, indent=2) + "\n")
    files = " ".join(shlex.quote(f) for f in outside)
    return {
        "decision": "block",
        "reason": (
            f"these changes are outside audit {lease['audit']}: {', '.join(outside)}. "
            f"Revert them (e.g. `git checkout {lease['base'] or 'HEAD'} -- <file>` for tracked files, `rm` for new "
            f"ones; commit the revert if the change was committed). Files: {files}. "
            "If you can't, list them as unresolved in your final report."
        ),
    }


# --------------------------------------------------------------------------------------------


def main() -> int:
    payload = json.load(sys.stdin)
    agent = sys.argv[1] if len(sys.argv) > 1 else payload.get("agent_type", "")
    event = payload.get("hook_event_name", "")
    out = None
    try:
        if event in ("Stop", "SubagentStop"):
            if agent == AUDITOR:
                record(payload)
            elif agent == IMPLEMENTER:
                out = stop_check(payload)
        elif event == "PreToolUse":
            out = protect_registry(payload)
            if out is None and payload.get("tool_name") in ("Agent", "Task"):
                out = launch(payload)
            if out is None and agent == IMPLEMENTER:
                out = scope(payload)
    except Exception as error:  # fail closed for the implementer, open for everyone else
        tool_input = payload.get("tool_input") or {}
        launching = tool_input.get("subagent_type") == IMPLEMENTER
        if event == "PreToolUse" and (agent == IMPLEMENTER or launching):
            out = deny(f"audit-gate error, refusing: {error}")
        else:
            print(f"audit-gate: {error}", file=sys.stderr)
    if out:
        print(json.dumps(out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
