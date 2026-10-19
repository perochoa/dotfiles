#!/usr/bin/env python3
"""Post inline diff comments on a GitLab MR.

Usage:
    python3 post_review_comments.py <mr_iid> <findings_json_file>

The findings file is a JSON array of {"file": ..., "line": ..., "body": ...} objects
(use "old_line" instead of "line" for removed lines). The project id and diff_refs SHAs
are read from the MR itself, so run this right before posting: SHAs change on every push.

Requires: glab CLI (authenticated)
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
import time


def mr_refs(mr_iid: str) -> tuple[str, str, str, str] | None:
    """Return (project_id, base_sha, head_sha, start_sha) for the MR, or None after printing why."""
    result = subprocess.run(
        ["glab", "mr", "view", mr_iid, "--output=json"],
        capture_output=True, text=True, timeout=60,
    )
    if result.returncode != 0:
        print(f"ERROR: glab mr view {mr_iid} failed: {result.stderr.strip()}", file=sys.stderr)
        return None
    try:
        mr = json.loads(result.stdout)
    except json.JSONDecodeError as e:
        print(f"ERROR: Could not parse MR JSON: {e}", file=sys.stderr)
        return None
    project_id = mr.get("project_id") or mr.get("target_project_id")
    if not project_id:
        print("ERROR: Could not determine project ID from MR JSON", file=sys.stderr)
        return None
    refs = mr.get("diff_refs") or {}
    shas = [refs.get(k, "") for k in ("base_sha", "head_sha", "start_sha")]
    if not all(shas):
        print("ERROR: Could not extract diff_refs SHAs from MR", file=sys.stderr)
        return None
    return str(project_id), *shas


def post_comments(project_id: str, mr_iid: str, findings_file: str,
                  base_sha: str, head_sha: str, start_sha: str) -> int:
    """Post inline review comments and return exit code."""
    print(f"Using SHAs — base: {base_sha[:8]}… head: {head_sha[:8]}… start: {start_sha[:8]}…")

    with open(findings_file) as f:
        content = f.read().strip()
        if not content:
            print("No findings in file.")
            return 0
        try:
            findings = json.loads(content)
        except json.JSONDecodeError as e:
            print(f"ERROR: Invalid JSON in findings file: {e}", file=sys.stderr)
            return 1

    if not isinstance(findings, list):
        print("ERROR: Findings file must contain a JSON array", file=sys.stderr)
        return 1

    if not findings:
        print("No findings in file.")
        return 0

    print(f"Posting {len(findings)} inline comment(s)…\n")

    errors = 0
    for i, finding in enumerate(findings, 1):
        position = {
            "position_type": "text",
            "old_path": finding["file"],
            "new_path": finding["file"],
            "base_sha": base_sha,
            "head_sha": head_sha,
            "start_sha": start_sha,
        }
        if "old_line" in finding:
            position["old_line"] = finding["old_line"]
        else:
            position["new_line"] = finding.get("line", finding.get("new_line"))

        payload = {
            "body": finding["body"],
            "position": position,
        }
        result = subprocess.run(
            ["glab", "api",
             f"/projects/{project_id}/merge_requests/{mr_iid}/discussions",
             "--method", "POST", "--input", "-",
             "-H", "Content-Type: application/json"],
            input=json.dumps(payload), capture_output=True, text=True, timeout=30,
        )
        if result.returncode != 0:
            line_ref = finding.get("old_line") or finding.get("line", finding.get("new_line", "?"))
            print(f"  [{i}/{len(findings)}] ERROR: {finding['file']}:{line_ref} — "
                  f"glab api exited with code {result.returncode}")
            if result.stderr:
                print(f"    stderr: {result.stderr.strip()}")
            errors += 1
            continue

        try:
            resp = json.loads(result.stdout)
            note_type = resp["notes"][0].get("type", "unknown")
            line_ref = finding.get("old_line") or finding.get("line", finding.get("new_line", "?"))
            if note_type != "DiffNote":
                print(f"  [{i}/{len(findings)}] WARNING: {finding['file']}:{line_ref} — "
                      f"got {note_type} instead of DiffNote (comment is not inline!)")
                errors += 1
            else:
                print(f"  [{i}/{len(findings)}] OK: {finding['file']}:{line_ref}")
        except (json.JSONDecodeError, KeyError, IndexError) as e:
            line_ref = finding.get("old_line") or finding.get("line", finding.get("new_line", "?"))
            print(f"  [{i}/{len(findings)}] ERROR: {finding['file']}:{line_ref} — {e}")
            if result.stderr:
                print(f"    stderr: {result.stderr.strip()}")
            errors += 1

        time.sleep(0.5)

    print(f"\nDone. {len(findings) - errors}/{len(findings)} comments placed inline.")
    if errors:
        print(f"WARNING: {errors} comment(s) failed or were not placed inline.", file=sys.stderr)
        return 1
    return 0


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print("Usage: post-review-comments.sh <mr_iid> <findings_json_file>\n\n"
              '  findings_json_file: JSON array of {"file": ..., "line": ..., "body": ...}',
              file=sys.stderr)
        return 1
    mr_iid, findings_file = argv
    if not os.path.isfile(findings_file):
        print(f"ERROR: Findings file not found: {findings_file}", file=sys.stderr)
        return 1
    if subprocess.run(["glab", "auth", "status"], capture_output=True).returncode != 0:
        print("ERROR: Not authenticated. Run: glab auth login", file=sys.stderr)
        return 1
    refs = mr_refs(mr_iid)
    if refs is None:
        return 1
    project_id, base_sha, head_sha, start_sha = refs
    return post_comments(project_id, mr_iid, findings_file, base_sha, head_sha, start_sha)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
