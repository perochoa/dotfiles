# paginate-api.sh — Shared pagination helper for GitLab API endpoints
#
# Usage:
#   source "$(dirname "$0")/paginate-api.sh"
#   paginate_api "/projects/:id/some_endpoint" "per_page=100&extra=param" output.json
#
# Fetches all pages from a GitLab API endpoint, writing a single JSON array
# to the output file. Uses per_page=100 and stops when a page returns fewer
# than 100 items (or an empty array).
#
# Arguments:
#   $1 — API endpoint path (e.g. "/projects/:id/vulnerability_findings")
#   $2 — Query string parameters (e.g. "per_page=100&severity[]=high")
#   $3 — Output file path (will be overwritten)
#
# Requires: glab CLI (authenticated), python3
#
# NOTE: All command-substitution assignments use the `|| { return 1; }` pattern
# so that error handling works correctly whether or not `set -e` is active in
# the calling script.

paginate_api() {
  local endpoint="$1"
  local params="$2"
  local outfile="$3"

  local page=1
  local first=true

  echo "[" > "$outfile"
  while true; do
    local response
    response=$(glab api "${endpoint}?${params}&page=${page}" 2>&1) || {
      echo "ERROR: glab api call failed: $response" >&2
      echo "]" >> "$outfile"
      return 1
    }

    local count
    count=$(echo "$response" | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null) || {
      echo "ERROR: Failed to parse API response as JSON array" >&2
      echo "]" >> "$outfile"
      return 1
    }

    if [[ "$count" == "0" ]]; then
      break
    fi

    if [[ "$first" == "true" ]]; then
      first=false
    else
      echo "," >> "$outfile"
    fi

    echo "$response" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for i, item in enumerate(data):
    if i > 0: print(',')
    print(json.dumps(item))
" >> "$outfile"

    if [[ "$count" -lt 100 ]]; then
      break
    fi
    page=$((page + 1))
  done
  echo "]" >> "$outfile"
}
