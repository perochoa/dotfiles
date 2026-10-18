# Confluence Patterns

## CQL Quick Reference

```
# Operators
= "exact"    ~ "contains"    != "not"    in ("a", "b")

# Dates
lastModified > now("-7d")    created > now("-30d")

# Types
type = page    type = blogpost    type = attachment

# Logic
AND, OR, NOT
```

**Common queries:**
```
space = <SPACE_KEY> AND type = page
space = <SPACE_KEY> AND title ~ "architecture"
space = <SPACE_KEY> AND text ~ "deployment"
space = <SPACE_KEY> AND label = "runbook"
space = <SPACE_KEY> AND lastModified > now("-7d")
space = <SPACE_KEY> AND ancestor = "<page-id>"
```

## Navigation

- Use `confluence_get_spaces()` to discover available space keys — do not assume a space key matches the Jira project key.
- Search by title first, then use the `page_id` from results to get full content.
- Use `confluence_get_page_children()` to browse page hierarchies.

## Creating and Updating

- **Page titles are unique per space** — always search before creating.
- **Updates replace the entire body** — fetch current content first, modify, then update. This avoids deleting existing content.

## Troubleshooting

- **"Page title already exists"** — search for the existing page and update it instead
- **Search returns nothing** — verify space key with `confluence_get_spaces()`, check CQL syntax (`~` for text, `=` for exact)
- **Content not appearing** — newly created pages take a few minutes to be indexed for search
