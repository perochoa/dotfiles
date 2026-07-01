---
name: gitlab-cli
description: Interact with GitLab for code reviews, merge requests, security vulnerability review and remediation, and pipeline review and remediation. Uses the glab CLI tool. Use when the user wants to review or manage GitLab merge requests, investigate or fix CI/CD pipeline failures, review security vulnerability reports, or perform code review activities that go beyond standard git operations.
allowed-tools: Bash(glab:*)
---

# GitLab with glab CLI

## Authentication (Always Check First)

Before any GitLab operation, verify authentication:

```bash
# Check if already authenticated
glab auth status

# If not authenticated, log in interactively
glab auth login

# Log in non-interactively with a token (api + read_repository + write_repository scopes required)
glab auth login --hostname gitlab.com --token <token>

# For self-hosted GitLab
glab auth login --hostname gitlab.example.com --token <token>
```

See [references/authentication.md](references/authentication.md) for full auth setup details.

## Quick Start

```bash
# Check auth first
glab auth status

# List open merge requests for the current repo
glab mr list

# View a specific MR with comments
glab mr view 123 --comments

# See MR diff
glab mr diff 123

# Check pipeline status on current branch
glab ci status

# Stream a failing job's log
glab ci trace <job-id>

# List security vulnerabilities — use vulnerability_findings for actionable data
# NOTE: /vulnerabilities has no package/file info; /vulnerability_findings has everything
scripts/list-vulnerabilities.sh high
# Or manually:
glab api "/projects/:id/vulnerability_findings?severity=high&per_page=100"
```

## Merge Requests

Every merge request must have a clear description that explains the change, motivation, and relevant context, links, or ticket references. At least one code review pass is required before merging any merge request.

```bash
# List MRs
glab mr list                          # open MRs
glab mr list --all                    # all states
glab mr list --merged                 # merged only
glab mr list --label "needs-review"   # filter by label
glab mr list --assignee @me           # assigned to me
glab mr list --reviewer @me           # where I am reviewer
glab mr list --output=json            # JSON output

# View MR details
glab mr view 123
glab mr view 123 --comments           # include all comments & activities
glab mr view 123 --unresolved         # show only unresolved discussions
glab mr view 123 --output=json

# Update MR
glab mr update 123 --title "New title"
glab mr update 123 --description "Updated description"
glab mr update 123 --label "needs-review"

# Close / reopen
glab mr close 123
glab mr reopen 123

# Checkout MR locally to test
glab mr checkout 123
```

See [references/merge-requests.md](references/merge-requests.md) for full details.

## Code Review

**Code reviews should use inline diff comments, not general overview comments.** Keep code review and implementation in separate agent conversations or separate passes so review feedback stays independent from the fix work.

```bash
# View diff for a specific MR
glab mr diff 123

# View all discussions (resolved and unresolved)
glab mr view 123 --comments

# View only unresolved discussions
glab mr view 123 --unresolved

# Extract SHAs (do this RIGHT BEFORE posting — they change when new commits are pushed)
glab mr view 123 --output=json | jq '.diff_refs'

# Add an inline diff comment (MUST use JSON body with --input, NOT --field)
echo '{
  "body": "Consider extracting this into a helper function.",
  "position": {
    "position_type": "text",
    "old_path": "src/utils.py",
    "new_path": "src/utils.py",
    "new_line": 42,
    "base_sha": "<base_sha>",
    "head_sha": "<head_sha>",
    "start_sha": "<start_sha>"
  }
}' | glab api /projects/:id/merge_requests/123/discussions \
  --method POST --input - -H "Content-Type: application/json"

# Reply to a discussion thread
echo '{"body": "Good point, I will refactor this."}' \
  | glab api /projects/:id/merge_requests/123/discussions/<discussion-id>/notes \
    --method POST --input - -H "Content-Type: application/json"

# Resolve a discussion
glab api /projects/:id/merge_requests/123/discussions/<discussion-id> \
  --method PUT --field "resolved=true"

# Add a general comment (optional — only for meta-discussion like "LGTM")
glab mr note 123 --message "LGTM — approved."
```

**WARNING:** Using `--field "position[...]"` for inline comments silently creates
general overview comments instead of inline DiffNotes. Always use the JSON body
approach shown above and verify the response contains `"type": "DiffNote"`.

See [references/code-review.md](references/code-review.md) for full review workflow with Python batch posting.

### Code Review Scripts

Script paths below are relative to this skill's directory (resolve from the `Path:` in the skill invocation metadata).

```bash
# Post multiple inline review comments from a JSON file
scripts/post-review-comments.sh <mr_iid> <findings.json>

# List all inline DiffNotes on an MR (with pagination)
scripts/list-diff-notes.sh <mr_iid>

# Verify a discussion API response is an inline DiffNote
echo '<json>' | scripts/verify-inline-comment.sh
```

## Post-Creation Review

After creating a merge request with `glab mr create`, or after pushing to a branch with an open MR, initiate a code review:

1. **If in interactive mode**: Ask the user how to proceed:
   - **Review only** — Review the MR diff and post inline comments. No code changes.
   - **Review and fix** — Review, then implement fixes, then re-review (up to 3 iterations).
   - **Skip** — No review this time.
2. **If in autopilot mode**: Automatically start a review-only pass — post inline comments on the MR. Make code changes only if the user explicitly requests them. Log what you are doing so the user can abort if needed.

To review:
```bash
# Get the MR diff
glab mr diff <iid>

# View existing discussions
glab mr view <iid> --comments
```

Review the changes for quality, security, and correctness. Post findings as inline diff comments (see [Code Review](#code-review) above). Code review and implementation must always be separate passes — never review and fix in the same conversation. Limit the review→fix cycle to 3 iterations per merge request, and always wait for human approval before merging.

## CI/CD Pipelines

```bash
# List pipelines
glab ci list                          # recent pipelines for current project
glab ci list --status=failed          # only failed
glab ci list --status=running         # only running

# Get pipeline details
glab ci get                           # current branch latest
glab ci get --pipeline-id=12345
glab ci get --output=json

# Pipeline status summary
glab ci status                        # current branch

# Interactive pipeline view (shows all jobs)
glab ci view                          # current branch

# Stream job log in real time
glab ci trace <job-id>
glab ci trace <job-name>              # by name (latest pipeline)

# Retry a failed job
glab ci retry <job-id>

# Trigger a new pipeline on the current branch
glab ci run
glab ci run --variables KEY:value

# Get test report (via API)
glab api /projects/:id/pipelines/12345/test_report
```

See [references/pipelines.md](references/pipelines.md) for full pipeline remediation workflow.

## Security Vulnerabilities

**IMPORTANT:** There are two endpoints. Use the right one:
- `/vulnerability_findings` — **Use this one.** Has package names, versions, file paths, dependency trees.
- `/vulnerabilities` — Summary-level only. No package/file details. Only useful for state management (confirm/resolve/dismiss).

**GOTCHAS:**
- Default `per_page` is 20 — always add `per_page=100` or you silently miss findings
- Results come from the **default branch pipeline**, not your feature branch — already-fixed vulns will still appear until merged
- Use query string params (`?severity=high`), not `--field` flags — `--field` silently fails for some filters
- Findings are NOT deduplicated — the same CVE appears once per affected file

### One-Shot Scripts (Recommended)

Script paths below are relative to this skill's directory (resolve from the `Path:` in the skill invocation metadata).

```bash
# List all high-severity findings, deduplicated and formatted
scripts/list-vulnerabilities.sh high

# Critical + high
scripts/list-vulnerabilities.sh critical,high

# Filter by report type too
scripts/list-vulnerabilities.sh high dependency_scanning

# Show FULL detail for a specific vulnerability (description, solution, CVEs, links)
scripts/show-vulnerability.sh immutable
scripts/show-vulnerability.sh CVE-2026-29063
scripts/show-vulnerability.sh serialize-javascript
```

### Manual API Calls

```bash
# Dependency scanning findings with full detail (ALWAYS use per_page=100)
glab api "/projects/:id/vulnerability_findings?severity=high&report_type=dependency_scanning&per_page=100"

# SAST findings
glab api "/projects/:id/vulnerability_findings?report_type=sast&per_page=100"

# Parse dependency findings into a readable table
glab api "/projects/:id/vulnerability_findings?severity=high&per_page=100" | python3 -c "
import json, sys
data = json.load(sys.stdin)
seen = set()
for v in data:
    loc = v.get('location') or {}
    dep = loc.get('dependency') or {}
    pkg = (dep.get('package') or {}).get('name', 'N/A')
    ver = dep.get('version', 'N/A')
    f = loc.get('file', 'N/A')
    key = f'{pkg}|{ver}|{f}|{v.get(\"name\", \"\")}'
    if key not in seen:
        seen.add(key)
        print(f'{v[\"severity\"]:<10} {pkg}@{ver:<20} {f:<55} {v[\"name\"]}')  
"
```

### Response Structure (`/vulnerability_findings`)

Key fields in the JSON response array:
```
[
  {
    "name": "<vulnerability title>",
    "severity": "high",
    "state": "detected",
    "report_type": "dependency_scanning",  // or sast, secret_detection, dast
    "location": {
      "file": "path/to/package-lock.json",
      "dependency": {
        "package": { "name": "serialize-javascript" },
        "version": "6.0.2"
      },
      "start_line": 42  // for SAST findings
    },
    "solution": "Upgrade to version X.Y.Z",
    "identifiers": [{"type": "cve", "name": "CVE-2026-XXXXX"}],
    "links": [{"url": "https://..."}]
  }
]
```

For false positives, report your reasoning to the user rather than dismissing — let them make that decision in the GitLab UI.

See [references/security.md](references/security.md) for the full remediation workflow.

## Working With Multiple Projects

```bash
# All glab commands accept -R flag for explicit project
glab mr list -R owner/repo
glab ci list -R group/subgroup/repo

# The :id placeholder in API calls resolves to the current repo's ID automatically
# For explicit project ID use the numeric ID or URL-encoded path:
glab api /projects/1234/vulnerabilities
glab api /projects/group%2Frepo/vulnerabilities
```

## Specific Tasks

- **Authentication setup**: [references/authentication.md](references/authentication.md)
- **Merge request management**: [references/merge-requests.md](references/merge-requests.md)
- **Code review workflow**: [references/code-review.md](references/code-review.md)
- **Pipeline review and remediation**: [references/pipelines.md](references/pipelines.md)
- **Security vulnerability review and remediation**: [references/security.md](references/security.md)
