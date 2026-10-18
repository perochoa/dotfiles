# Code Review Workflow

## Viewing Changes

```bash
# View the full diff of an MR
glab mr diff 123

# View all discussions (resolved and unresolved)
glab mr view 123 --comments

# View only unresolved discussions (focus on what needs action)
glab mr view 123 --unresolved

# View only resolved discussions (audit trail)
glab mr view 123 --resolved

# Get MR metadata as JSON (includes diff refs: base_sha, head_sha, start_sha)
glab mr view 123 --output=json
```

## Extracting SHAs for Inline Comments

Inline diff comments require three commit SHAs from the MR. Extract them
**immediately before posting** — SHAs change when new commits are pushed:

```bash
# Get the SHAs needed for inline comments
glab mr view 123 --output=json | python3 -c "
import json, sys
mr = json.load(sys.stdin)
dc = mr.get('diff_refs', {})
print('base_sha:', dc.get('base_sha'))
print('head_sha:', dc.get('head_sha'))
print('start_sha:', dc.get('start_sha'))
"
```

Or with `jq`:

```bash
glab mr view 123 --output=json | jq '{base_sha: .diff_refs.base_sha, head_sha: .diff_refs.head_sha, start_sha: .diff_refs.start_sha}'
```

## Adding Inline Diff Comments

**Code reviews should use inline diff comments, not general overview comments.**
Place each review finding directly on the relevant line in the diff.

Inline comments **must** be sent as a JSON body with `Content-Type: application/json`.
Using `--field` for nested position parameters silently creates general comments instead.

**IMPORTANT:**
- Always include **both** `old_path` and `new_path` (same value when file is not renamed)
- The `new_line` must reference a line visible in the diff (within a hunk range)
- Always verify the response contains `"type": "DiffNote"` — if it says `"DiscussionNote"`, the comment was not placed inline

### Comment on a new/changed line

```bash
echo '{
  "body": "Consider extracting this into a helper function to improve reusability.",
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
```

### Comment on a removed line

```bash
echo '{
  "body": "This old approach had a race condition.",
  "position": {
    "position_type": "text",
    "old_path": "src/utils.py",
    "new_path": "src/utils.py",
    "old_line": 38,
    "base_sha": "<base_sha>",
    "head_sha": "<head_sha>",
    "start_sha": "<start_sha>"
  }
}' | glab api /projects/:id/merge_requests/123/discussions \
  --method POST --input - -H "Content-Type: application/json"
```

### Posting from Python (recommended for multiple comments)

When posting many inline comments (e.g., a full code review), use the helper
script to avoid shell escaping issues with markdown, backticks, and special
characters. It extracts SHAs automatically and verifies each comment is placed
inline.

Use the helper script: `scripts/post-review-comments.sh`

```bash
# Create a findings JSON file:
cat > findings.json <<'EOF'
[
  {"file": "src/utils.py", "line": 42, "body": "Your review comment here..."},
  {"file": "src/main.py", "line": 10, "body": "Another comment..."}
]
EOF

# Post all comments:
scripts/post-review-comments.sh 123 findings.json
```

### Verifying inline placement

After posting, always verify the response is an inline DiffNote.

Use the helper script: `scripts/verify-inline-comment.sh`

```bash
# Pipe a discussion API response to verify it was placed inline:
echo '<response_json>' | scripts/verify-inline-comment.sh
```

If you get `DiscussionNote` instead of `DiffNote`, the most common causes are:
1. Missing `Content-Type: application/json` header (used `--field` instead of `--input`)
2. Missing `old_path` in the position
3. Stale `head_sha` (new commits were pushed — re-extract SHAs)
4. `new_line` is not within any diff hunk range

## Adding General Comments (Optional)

General comments go in the MR overview, not on the diff. **Prefer inline comments
for code review.** Use general comments only for meta-discussion (e.g., "LGTM",
"blocked on dependency upgrade").

```bash
# Simple one-line comment
glab mr note 123 --message "LGTM — approved."

# Multi-line / complex markdown: use command substitution to pass file contents
glab mr note 123 --message "$(cat review_summary.md)"
```

## Listing Discussions via API

```bash
# Get all discussion threads with full detail
glab api /projects/:id/merge_requests/123/discussions

# Pretty print with jq
glab api /projects/:id/merge_requests/123/discussions | jq '.[] | {id: .id, resolved: .resolved, notes: [.notes[] | {id: .id, author: .author.username, body: .body, resolvable: .resolvable}]}'

# Get all notes (flattened, not threaded)
glab api /projects/:id/merge_requests/123/notes

# Show only inline DiffNotes (verify your comments landed correctly)
scripts/list-diff-notes.sh 123
```

## Replying to Discussion Threads

When responding to an existing discussion thread (not starting a new one):

```bash
# Reply to an existing discussion thread
echo '{"body": "Good point — I have updated this in the latest commit."}' \
  | glab api /projects/:id/merge_requests/123/discussions/<discussion-id>/notes \
    --method POST --input - -H "Content-Type: application/json"
```

The `<discussion-id>` is the `id` field from the discussion object (a long hex string).

## Resolving and Unresolving Discussions

```bash
# Resolve via API by discussion ID (most reliable)
glab api /projects/:id/merge_requests/123/discussions/<discussion-id> \
  --method PUT \
  --field "resolved=true"

# Unresolve via API
glab api /projects/:id/merge_requests/123/discussions/<discussion-id> \
  --method PUT \
  --field "resolved=false"

# Resolve by note ID (glab shorthand)
glab mr note 123 --resolve <note-id>

# Unresolve by note ID
glab mr note 123 --unresolve <note-id>
```

## Full Code Review Workflow Example

```bash
# 1. Check auth
glab auth status

# 2. Find MRs needing review
glab mr list --reviewer @me

# 3. View the MR details and description
glab mr view 123

# 4. See the diff
glab mr diff 123

# 5. Check any unresolved discussions from previous reviews
glab mr view 123 --unresolved

# 6. Extract SHAs for inline comments (do this RIGHT BEFORE posting)
glab mr view 123 --output=json | jq '.diff_refs'

# 7. Post inline comments on the diff (use Python for multiple comments)
#    See "Posting from Python" section above.
#    Each comment must be a JSON body piped via --input with Content-Type header.

# 8. After author fixes — resolve the discussion
glab api /projects/:id/merge_requests/123/discussions/<discussion-id> \
  --method PUT \
  --field "resolved=true"
```

## Finding Note/Discussion IDs

```bash
# List all notes with IDs
glab api /projects/:id/merge_requests/123/notes | jq '.[] | {id: .id, author: .author.username, body: .body[0:80]}'

# List all discussions with IDs
glab api /projects/:id/merge_requests/123/discussions | jq '.[] | {id: .id, resolved: .resolved, first_note: .notes[0].body[0:80]}'
```
