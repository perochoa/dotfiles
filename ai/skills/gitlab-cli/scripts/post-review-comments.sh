#!/usr/bin/env bash
# post-review-comments.sh — Post multiple inline diff comments on a GitLab MR
#
# Usage:
#   ./post-review-comments.sh <mr_iid> <findings_json_file>
#
# The findings JSON file must contain an array of objects with:
#   [{"file": "src/utils.py", "line": 42, "body": "Review comment..."}, ...]
#
# The work (auth check, SHA lookup, posting) is in post_review_comments.py.
# Requires: glab CLI (authenticated), python3
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$SCRIPT_DIR/post_review_comments.py" "$@"
