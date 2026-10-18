---
name: jira-confluence
description: Manage Jira issues and Confluence pages using the Atlassian MCP. Use when the user wants to create, search, update, or transition Jira issues, view sprint backlogs, search or create Confluence documentation pages, or coordinate work between Jira tickets and GitLab merge requests.
allowed-tools: mcp__atlassian__*
---

# Jira & Confluence with Atlassian MCP

## Authentication

Authentication is handled via the MCP server's OAuth flow — no manual token management required. On first use, the MCP server will prompt for Atlassian account authorization. If you encounter auth errors, restart the MCP connection to re-trigger OAuth.

## Quick Start

```
# Search current sprint
jira_search(jql: "project = <PROJECT_KEY> AND sprint in openSprints() ORDER BY priority DESC")

# Get issue details
jira_get_issue(issue_key: "<PROJECT_KEY>-123")

# Create issue (discover types first with jira_get_issue_types)
jira_create_issue(
  project_key: "<PROJECT_KEY>",
  issue_type: "<ISSUE_TYPE>",
  summary: "Implement feature X",
  parent_key: "<PROJECT_KEY>-100"
)

# Transition (discover transitions first)
jira_get_transitions(issue_key: "<PROJECT_KEY>-123")
jira_transition_issue(issue_key: "<PROJECT_KEY>-123", transition: "<transition-name>")

# Search Confluence
confluence_search(cql: "space = <SPACE_KEY> AND type = page AND text ~ 'runbook'")
```

## Post-Write Validation

After **every** create or update, read back and verify:
- Summary/title matches intended text
- Description/body markdown renders correctly (headings, bold, code blocks, links)
- No truncation, garbled characters, or broken formatting

If validation fails: report the issue, re-update with corrected formatting, re-verify.

> **Note:** Jira's markdown differs from standard markdown. Simplify formatting if it doesn't render correctly.

## Integration with gitlab-cli Skill

### Ticket → Branch → MR → Done

1. **Pick up ticket** — assign yourself, discover and apply the start-work transition
2. **Create branch** with ticket ID for auto-linking: `git checkout -b feature/<PROJECT_KEY>-123`
3. **Create MR** via gitlab-cli: `glab mr create --title "<PROJECT_KEY>-123: Description" --target-branch main`
4. **Transition to review** when MR is ready
5. **Transition to done** after merge

> **Tip:** GitLab auto-links MRs to Jira when commit messages or branch names contain the ticket ID.

## Reference Docs

- **Jira workflows and JQL syntax**: [references/jira-workflows.md](references/jira-workflows.md)
- **Confluence patterns and CQL syntax**: [references/confluence-patterns.md](references/confluence-patterns.md)
