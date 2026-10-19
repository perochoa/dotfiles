#!/usr/bin/env bash
# list-diff-notes.sh — List all inline DiffNotes on a GitLab MR
#
# Usage:
#   ./list-diff-notes.sh <mr_iid>
#
# Shows a summary of all inline diff comments with file, line, and truncated body.
# Useful for verifying that review comments were placed correctly on the diff.
#
# Requires: glab CLI (authenticated), python3
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

MR_IID="${1:-}"

if [[ -z "$MR_IID" ]]; then
  echo "Usage: $0 <mr_iid>" >&2
  exit 1
fi

# --- Validate MR_IID is a positive integer ---
if ! [[ "$MR_IID" =~ ^[1-9][0-9]*$ ]]; then
  echo "ERROR: MR_IID must be a positive integer, got: $MR_IID" >&2
  exit 1
fi

# --- Verify auth ---
if ! glab auth status &>/dev/null; then
  echo "ERROR: Not authenticated. Run: glab auth login" >&2
  exit 1
fi

# --- Fetch all pages of discussions ---
# shellcheck source=paginate-api.sh
source "${SCRIPT_DIR}/paginate-api.sh"

TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

if ! paginate_api "/projects/:id/merge_requests/${MR_IID}/discussions" "per_page=100" "$TMPFILE"; then
  echo "ERROR: Failed to fetch discussions from API" >&2
  exit 1
fi

python3 - "$TMPFILE" <<'PYEOF'
import json, sys

with open(sys.argv[1]) as f:
    data = json.load(f)

count = 0

for d in data:
    note = d['notes'][0]
    if note.get('type') == 'DiffNote' and note.get('position'):
        pos = note['position']
        body = note['body'][:60].replace(chr(10), ' ')
        line = pos.get('new_line') or pos.get('old_line', '?')
        print(f'{pos["new_path"]}:{line} | {body}...')
        count += 1

if count == 0:
    print('No inline DiffNotes found on this MR.')
else:
    print(f'\nTotal: {count} inline DiffNote(s)')
PYEOF
