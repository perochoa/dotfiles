# Merge Request Management

## Listing Merge Requests

```bash
# List open MRs for current repo
glab mr list

# All states
glab mr list --all
glab mr list                      # default: open MRs only
glab mr list --closed
glab mr list --merged

# Filter by assignee/reviewer/author
glab mr list --assignee @me
glab mr list --assignee username
glab mr list --reviewer @me
glab mr list --author username

# Filter by label
glab mr list --label "needs-review"
glab mr list --label "bug,hotfix"   # multiple labels (AND)

# Filter by milestone
glab mr list --milestone "v2.0"

# Filter by target branch
glab mr list --target-branch main

# Pagination
glab mr list --per-page=50
glab mr list --page=2

# JSON output for scripting
glab mr list --output=json
```

## Viewing MR Details

```bash
# View MR by ID
glab mr view 123

# View by branch name
glab mr view feature/my-branch

# Include all comments and activities
glab mr view 123 --comments

# Show only unresolved discussions
glab mr view 123 --unresolved

# Show only resolved discussions
glab mr view 123 --resolved

# Include system log events
glab mr view 123 --system-logs

# JSON output
glab mr view 123 --output=json

# Open in browser
glab mr view 123 --web
```

## Updating Merge Requests

```bash
# Update title
glab mr update 123 --title "refactor: improved approach"

# Update description
glab mr update 123 --description "Updated description with new approach"

# Add/change labels
glab mr update 123 --label "needs-review,ready-to-merge"

# Remove a label
glab mr update 123 --unlabel "needs-review"

# Add assignee
glab mr update 123 --assignee username

# Remove all assignees
glab mr update 123 --unassign

# Add reviewer
glab mr update 123 --reviewer username

# Change target branch
glab mr update 123 --target-branch develop

# Convert draft to ready
glab mr update 123 --ready

# Convert ready to draft
glab mr update 123 --draft
```

## Lifecycle Management

```bash
# Close an MR
glab mr close 123

# Reopen a closed MR
glab mr reopen 123

# Subscribe to MR notifications
glab mr subscribe 123

# Unsubscribe
glab mr unsubscribe 123

# Add to your to-do list
glab mr todo 123
```

## Checking Out MR Locally

```bash
# Checkout MR branch locally to test it
glab mr checkout 123

# Checkout and create a new local branch name
glab mr checkout 123 --branch local-test-branch

# After testing, switch back
git checkout main
```

## Working With Other Projects

```bash
# All commands accept -R for explicit project
glab mr list -R owner/repo
glab mr view 123 -R group/subgroup/project
```
