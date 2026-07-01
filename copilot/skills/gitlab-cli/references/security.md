# Security Vulnerability Review and Remediation

## Critical Gotchas

1. **Use `/vulnerability_findings`, not `/vulnerabilities`** — The `/vulnerabilities` endpoint only has summary data (title, severity, state). It does NOT include package names, versions, or file paths. The `/vulnerability_findings` endpoint has everything you need.
2. **Always add `per_page=100`** — Default is 20, and you silently miss findings without it.
3. **Use query string params, not `--field` flags** — `--field severity=high` silently fails on some endpoints. Use `?severity=high` in the URL instead.
4. **Results come from the default branch** — Scans reflect the latest pipeline on main/master, not your feature branch. Findings you've already fixed on your branch will still appear until merge.
5. **Findings are not deduplicated** — The same CVE in 8 different files = 8 separate findings. You must deduplicate yourself.

## One-Shot Scripts (Recommended)

Use the helper scripts instead of raw API calls:

```bash
# LIST: All high-severity findings, deduplicated and formatted as a table
scripts/list-vulnerabilities.sh high

# LIST: Multiple severities
scripts/list-vulnerabilities.sh critical,high

# LIST: Filter by report type (sast, dependency_scanning, secret_detection, dast)
scripts/list-vulnerabilities.sh high dependency_scanning

# DETAIL: Full description, solution, CVEs, links for a specific vulnerability
# Search by package name, CVE, GHSA, or title keyword:
scripts/show-vulnerability.sh immutable
scripts/show-vulnerability.sh CVE-2026-29063
scripts/show-vulnerability.sh serialize-javascript
scripts/show-vulnerability.sh tar
```

## Overview

GitLab security scanning results are accessed via the API using `glab api`. The main endpoints are:
- `/projects/:id/vulnerability_findings` — **primary**: raw findings with full detail (package, version, file, line)
- `/projects/:id/vulnerabilities` — **secondary**: aggregated entries, only for state management (confirm/resolve/dismiss)

## Listing Vulnerabilities

```bash
# All detected vulnerabilities (paginated, 20 per page by default)
glab api /projects/:id/vulnerabilities

# Pretty print with jq
glab api /projects/:id/vulnerabilities | jq '.[] | {id: .id, severity: .severity, title: .title, state: .state, scanner: .scanner.name}'

# Filter by severity: critical, high, medium, low, info, unknown
glab api "/projects/:id/vulnerabilities?severity=critical"
glab api "/projects/:id/vulnerabilities?severity=high"

# Filter by state: detected, confirmed, resolved, dismissed
glab api "/projects/:id/vulnerabilities?state=detected"
glab api "/projects/:id/vulnerabilities?state=confirmed"

# Combine filters
glab api "/projects/:id/vulnerabilities?severity=critical&state=detected"
glab api "/projects/:id/vulnerabilities?severity=high&state=detected"

# Multiple severity levels (repeat parameter)
glab api "/projects/:id/vulnerabilities?severity[]=critical&severity[]=high"

# Pagination
glab api "/projects/:id/vulnerabilities?per_page=100&page=1"

# Sort by severity (most severe first)
glab api "/projects/:id/vulnerabilities?sort=desc&order_by=severity"
```

## Getting Vulnerability Details

```bash
# Get a specific vulnerability by ID
glab api /projects/:id/vulnerabilities/12345

# Get full details including remediation advice
glab api /projects/:id/vulnerabilities/12345 | jq '{
  title: .title,
  severity: .severity,
  state: .state,
  description: .description,
  solution: .solution,
  cve: .identifiers[] | select(.type == "cve") | .value,
  scanner: .scanner.name,
  location: .location,
  links: .links
}'
```

## Vulnerability Findings (Pipeline-Level)

Pipeline findings give raw scan results tied to a specific pipeline run:

```bash
# All findings for the latest default branch pipeline (ALWAYS use per_page=100)
glab api "/projects/:id/vulnerability_findings?per_page=100"

# Findings for a specific pipeline
glab api "/projects/:id/vulnerability_findings?pipeline_id=12345&per_page=100"

# Filter by report type: sast, dast, dependency_scanning, secret_detection, container_scanning
glab api "/projects/:id/vulnerability_findings?report_type=sast&per_page=100"
glab api "/projects/:id/vulnerability_findings?report_type=dependency_scanning&per_page=100"
glab api "/projects/:id/vulnerability_findings?report_type=secret_detection&per_page=100"

# Filter by scope: all (default) or dismissed
glab api "/projects/:id/vulnerability_findings?scope=all&per_page=100"

# Filter findings by severity
glab api "/projects/:id/vulnerability_findings?pipeline_id=12345&severity=critical&per_page=100"

# Summarize findings
glab api "/projects/:id/vulnerability_findings?pipeline_id=12345&per_page=100" | \
  jq 'group_by(.severity) | .[] | {severity: .[0].severity, count: length}'
```

### Response Structure

The `/vulnerability_findings` response is a JSON array. Key fields:

```json
[
  {
    "id": 22165455295,
    "name": "Vulnerability title / description",
    "severity": "high",
    "state": "detected",
    "report_type": "dependency_scanning",
    "location": {
      "file": "path/to/package-lock.json",
      "dependency": {
        "package": { "name": "serialize-javascript" },
        "version": "6.0.2"
      },
      "start_line": 42
    },
    "solution": "Upgrade to version 7.0.3 or later",
    "description": "Full HTML description of the vulnerability...",
    "identifiers": [
      { "type": "cve", "name": "CVE-2026-XXXXX", "value": "CVE-2026-XXXXX" },
      { "type": "ghsa", "name": "GHSA-XXXX-XXXX-XXXX" }
    ],
    "links": [{ "url": "https://nvd.nist.gov/..." }],
    "blob_path": "/group/project/-/blob/<sha>/path/to/file#L42"
  }
]
```

**Field extraction cheatsheet (Python — use this, not jq, for complex parsing):**
```python
for v in data:
    title    = v["name"]
    severity = v["severity"]
    report   = v["report_type"]                              # sast, dependency_scanning, etc.
    file     = v["location"]["file"]                         # always present
    pkg      = v["location"]["dependency"]["package"]["name"] # dependency_scanning only
    version  = v["location"]["dependency"]["version"]         # dependency_scanning only
    line     = v["location"].get("start_line")               # SAST only
```

**Deduplication pattern:** Same CVE appears once per affected file. Deduplicate by `(package, version, file, title)`:
```python
seen = set()
for v in data:
    key = f"{pkg}|{version}|{file}|{title}"
    if key in seen: continue
    seen.add(key)
```

## Reviewing Vulnerability Reports by Type

### SAST (Static Application Security Testing)

```bash
# List SAST findings
glab api "/projects/:id/vulnerability_findings?report_type=sast" | \
  jq '.[] | {title: .name, severity: .severity, file: .location.file, line: .location.start_line, description: .description}'
```

### Dependency Scanning

```bash
# List dependency vulnerabilities
glab api "/projects/:id/vulnerability_findings?report_type=dependency_scanning" | \
  jq '.[] | {title: .name, severity: .severity, package: .location.dependency.package.name, version: .location.dependency.version, fixed_in: .solution}'
```

### Secret Detection

```bash
# List detected secrets (high priority — rotate immediately!)
glab api "/projects/:id/vulnerability_findings?report_type=secret_detection" | \
  jq '.[] | {title: .name, severity: .severity, file: .location.file, line: .location.start_line}'
```

### DAST (Dynamic Application Security Testing)

```bash
# List DAST findings
glab api "/projects/:id/vulnerability_findings?report_type=dast" | \
  jq '.[] | {title: .name, severity: .severity, url: .location.hostname, description: .description}'
```

## Vulnerability State Management

```bash
# Confirm a vulnerability (acknowledge it is real)
glab api /projects/:id/vulnerabilities/12345/confirm --method POST

# Resolve a vulnerability (mark as fixed after the code change is in)
glab api /projects/:id/vulnerabilities/12345/resolve --method POST

# Revert to detected state
glab api /projects/:id/vulnerabilities/12345/revert --method POST
```

## Handling False Positives

Do not dismiss vulnerabilities via the API. Instead, report the suspected false positive to the user directly with your reasoning:

- Explain **why** you believe it is a false positive (e.g., the flagged code path is only reachable in tests, the secret is a dummy value in a fixture, the dependency is already patched at a higher level)
- Include the vulnerability ID, title, and scanner name so the user can investigate in the GitLab UI and make the dismiss decision themselves
- If you need more context, fetch the full vulnerability details:

```bash
glab api /projects/:id/vulnerabilities/12345 | jq '{title: .title, description: .description, solution: .solution, location: .location, links: .links}'
```

## Remediation Workflow

### Step 1: Triage Critical Findings

```bash
# Get all critical and high severity detected vulnerabilities
glab api "/projects/:id/vulnerabilities?severity=critical&state=detected" | \
  jq '.[] | {id: .id, title: .title, scanner: .scanner.name, solution: .solution}'

glab api "/projects/:id/vulnerabilities?severity=high&state=detected" | \
  jq '.[] | {id: .id, title: .title, scanner: .scanner.name, solution: .solution}'
```

### Step 2: Fix the Vulnerability

Make the code change on the current working branch:

```bash
# Make the fix (update dependency, patch code, remove secret, etc.)
# ... edit the relevant files ...

git add .
git commit -m "security: fix CVE-YYYY-NNNNN - <brief description>"
git push
```

Common fix patterns:
- **Dependency vulnerability**: Update the package version in your lock file / requirements
- **SAST finding**: Refactor the flagged code pattern (e.g., replace unsafe deserialization, sanitize inputs)
- **Secret detection**: Remove the secret from code, rotate the credential, add the file to `.gitignore`
- **DAST finding**: Fix the web application behavior (missing headers, open redirects, etc.)

### Step 3: Verify the Fix

After the pipeline runs on the fix branch, confirm the finding is gone:

```bash
# Get the latest pipeline ID on the current branch
PIPELINE_ID=$(glab ci get --output=json | jq -r '.id')

# Check that the finding no longer appears
glab api "/projects/:id/vulnerability_findings?pipeline_id=$PIPELINE_ID&report_type=sast" | jq 'length'

# Or check for a specific finding by name
glab api "/projects/:id/vulnerability_findings?pipeline_id=$PIPELINE_ID" | \
  jq '[.[] | select(.name | test("<vulnerability name>"; "i"))]'
```

## Bulk Triage

```bash
# Count vulnerabilities by severity
glab api /projects/:id/vulnerabilities | \
  jq 'group_by(.severity) | .[] | {severity: .[0].severity, count: length}'

# List all critical vulnerabilities with their solution
glab api "/projects/:id/vulnerabilities?severity=critical&state=detected&per_page=100" | \
  jq '.[] | "ID: \(.id)\nTitle: \(.title)\nSolution: \(.solution // "No solution provided")\n"' -r

# Export to CSV for tracking
glab api "/projects/:id/vulnerabilities?per_page=100" | \
  jq -r '.[] | [.id, .severity, .state, .title, .scanner.name] | @csv' > vulnerabilities.csv
```
