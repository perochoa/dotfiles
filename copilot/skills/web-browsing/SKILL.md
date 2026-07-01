---
name: web-browsing
description: Web lookup and browser-tool guidance. Use for choosing between Playwright, fetch/search tools, and Atlassian MCP access.
---

# Web Browsing & Content Fetching Guidance

**Playwright** (when available) is the **default tool** for app development and debugging tasks — use it when running or inspecting apps locally, debugging deployed apps, or interacting with any JS-rendered UI.

For **general web lookups** (documentation, APIs, static pages), use the built-in search and fetch tools — they are faster and lighter.

When a page requires full browser rendering (SPAs, login walls, complex dashboards), Playwright can navigate, screenshot, and OCR the content.

For **Jira and Confluence** content, always prefer the Atlassian MCP tools over browser-based access.
