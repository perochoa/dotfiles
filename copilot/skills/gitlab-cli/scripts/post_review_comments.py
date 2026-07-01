#!/usr/bin/env python3
"""Post inline diff comments on a GitLab MR.

Usage:
    python3 post_review_comments.py <project_id> <mr_iid> <findings_json_file> <base_sha> <head_sha> <start_sha>

Requires: glab CLI (authenticated)
"""
import subprocess
import json
import sys
import time


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


if __name__ == "__main__":
    if len(sys.argv) != 7:
        print("Usage: python3 post_review_comments.py <project_id> <mr_iid> "
              "<findings_json_file> <base_sha> <head_sha> <start_sha>", file=sys.stderr)
        sys.exit(1)
    sys.exit(post_comments(*sys.argv[1:7]))
