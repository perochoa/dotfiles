#!/usr/bin/env bash
# post-review-comments.sh — Post multiple inline diff comments on a GitLab MR
#
# Usage:
#   ./post-review-comments.sh <mr_iid> <findings_json_file>
#
# The findings JSON file must contain an array of objects with:
#   [{"file": "src/utils.py", "line": 42, "body": "Review comment..."}, ...]
#
# SHAs are extracted automatically from the MR. Run this right before posting
# since SHAs change when new commits are pushed.
#
# Requires: glab CLI (authenticated), python3
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MR_IID="${1:-}"
FINDINGS_FILE="${2:-}"

if [[ -z "$MR_IID" || -z "$FINDINGS_FILE" ]]; then
  echo "Usage: $0 <mr_iid> <findings_json_file>" >&2
  echo "" >&2
  echo "  findings_json_file: JSON array of {\"file\": ..., \"line\": ..., \"body\": ...}" >&2
  exit 1
fi

if [[ ! -f "$FINDINGS_FILE" ]]; then
  echo "ERROR: Findings file not found: $FINDINGS_FILE" >&2
  exit 1
fi

# --- Verify auth ---
if ! glab auth status &>/dev/null; then
  echo "ERROR: Not authenticated. Run: glab auth login" >&2
  exit 1
fi

# --- Extract SHAs and project ID from the MR ---
MR_JSON=$(glab mr view "$MR_IID" --output=json)

eval "$(echo "$MR_JSON" | python3 -c "
import json, sys
mr = json.load(sys.stdin)
pid = mr.get('project_id') or mr.get('target_project_id')
if not pid:
    print('echo \"ERROR: Could not determine project ID from MR JSON\" >&2; exit 1')
    sys.exit(0)
dc = mr.get('diff_refs') or {}
base = dc.get('base_sha', '')
head = dc.get('head_sha', '')
start = dc.get('start_sha', '')
if not all([base, head, start]):
    print('echo \"ERROR: Could not extract diff_refs SHAs from MR\" >&2; exit 1')
    sys.exit(0)
print(f\"PROJECT_ID='{pid}'\")
print(f\"BASE_SHA='{base}'\")
print(f\"HEAD_SHA='{head}'\")
print(f\"START_SHA='{start}'\")
")"

# --- Post comments ---
python3 "$SCRIPT_DIR/post_review_comments.py" \
  "$PROJECT_ID" "$MR_IID" "$FINDINGS_FILE" "$BASE_SHA" "$HEAD_SHA" "$START_SHA"
