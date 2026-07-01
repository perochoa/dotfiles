#!/usr/bin/env bash
# list-vulnerabilities.sh — One-shot GitLab vulnerability report
#
# Usage:
#   ./list-vulnerabilities.sh                    # all severities
#   ./list-vulnerabilities.sh high               # filter by severity
#   ./list-vulnerabilities.sh critical,high       # multiple severities
#   ./list-vulnerabilities.sh high sast          # severity + report type
#
# Requires: glab CLI (authenticated), python3
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

SEVERITY="${1:-}"
REPORT_TYPE="${2:-}"

# --- Verify auth ---
if ! glab auth status &>/dev/null; then
  echo "ERROR: Not authenticated. Run: glab auth login" >&2
  exit 1
fi

# --- Build query params ---
PARAMS="per_page=100"
if [[ -n "$SEVERITY" ]]; then
  # GitLab API needs severity[]=x&severity[]=y for multiple values
  IFS=',' read -ra SEV_ARRAY <<< "$SEVERITY"
  for sev in "${SEV_ARRAY[@]}"; do
    PARAMS="${PARAMS}&severity[]=${sev}"
  done
fi
if [[ -n "$REPORT_TYPE" ]]; then
  PARAMS="${PARAMS}&report_type=${REPORT_TYPE}"
fi

TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

# --- Fetch all pages using shared helper ---
# shellcheck source=paginate-api.sh
source "${SCRIPT_DIR}/paginate-api.sh"

if ! paginate_api "/projects/:id/vulnerability_findings" "$PARAMS" "$TMPFILE"; then
  echo "ERROR: Failed to fetch vulnerability findings from API" >&2
  exit 1
fi

# --- Parse and display ---
python3 << 'PYEOF' - "$TMPFILE"
import json, sys

with open(sys.argv[1]) as f:
    data = json.load(f)

if not data:
    print("No vulnerability findings found.")
    sys.exit(0)

seen = set()
rows = []

for v in data:
    title = v.get("name", "N/A")
    severity = v.get("severity", "N/A").upper()
    report = v.get("report_type", "N/A")
    state = v.get("state", "N/A")
    loc = v.get("location") or {}
    file_path = loc.get("file", "N/A")
    dep = loc.get("dependency") or {}
    pkg_info = dep.get("package") or {}
    pkg = pkg_info.get("name", "N/A")
    ver = dep.get("version", "N/A")

    # Deduplicate by package+version+file+title
    key = f"{pkg}|{ver}|{file_path}|{title}"
    if key in seen:
        continue
    seen.add(key)

    # Build display package string
    if pkg != "N/A" and ver != "N/A":
        pkg_display = f"{pkg}@{ver}"
    elif pkg != "N/A":
        pkg_display = pkg
    else:
        pkg_display = "(no package)"

    rows.append({
        "severity": severity,
        "report": report,
        "package": pkg_display,
        "file": file_path,
        "title": title,
        "state": state,
    })

# Sort by severity (CRITICAL first), then report type, then package
severity_order = {"CRITICAL": 0, "HIGH": 1, "MEDIUM": 2, "LOW": 3, "INFO": 4, "UNKNOWN": 5}
rows.sort(key=lambda r: (severity_order.get(r["severity"], 9), r["report"], r["package"]))

# Print header
print(f"\n{'SEVERITY':<10} {'TYPE':<22} {'PACKAGE':<40} {'FILE':<55} TITLE")
print("=" * 160)

current_severity = None
for r in rows:
    if r["severity"] != current_severity:
        if current_severity is not None:
            print("-" * 160)
        current_severity = r["severity"]
    print(f"{r['severity']:<10} {r['report']:<22} {r['package']:<40} {r['file']:<55} {r['title']}")

print(f"\n  Total unique findings: {len(rows)}")

# Summary by severity
from collections import Counter
sev_counts = Counter(r["severity"] for r in rows)
print(f"  Breakdown: {', '.join(f'{s}: {c}' for s, c in sorted(sev_counts.items(), key=lambda x: severity_order.get(x[0], 9)))}")

# Summary by report type
type_counts = Counter(r["report"] for r in rows)
print(f"  By type:   {', '.join(f'{t}: {c}' for t, c in sorted(type_counts.items()))}")
print()
PYEOF
