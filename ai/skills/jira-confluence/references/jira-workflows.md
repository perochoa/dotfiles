# Jira Workflows

## Key Principles

- **Discover dynamically** — never hardcode issue types, transitions, or field names. Use MCP tools to query what's available.
- **Transitions are case-sensitive** — always call `jira_get_transitions` before transitioning an issue.
- **Search before creating** — avoid duplicates by searching JQL first.

## JQL Quick Reference

```
# Operators
=, !=, ~, !~, in, not in, is EMPTY, is not EMPTY

# Dates
field >= -7d    field >= startOfWeek()    field >= "2024-01-01"

# Logic
AND, OR, NOT    (A OR B) AND C

# Text search
summary ~ "keyword"    text ~ "keyword"
```

**Useful queries:**
```
project = <KEY> AND sprint in openSprints() ORDER BY priority DESC
project = <KEY> AND assignee = currentUser() AND status != Done
project = <KEY> AND type = Bug AND status != Done
project = <KEY> AND updated >= -3d
project = <KEY> AND parent = <KEY>-100
```

## Troubleshooting

- **"No valid transitions"** — call `jira_get_transitions` to see available transitions from the current state
- **Search returns nothing** — use `~` for text search (not `=`), quote multi-word values: `status = "In Progress"`
