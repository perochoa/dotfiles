---
name: documentation-standards
description: Documentation guidance. Use for README structure, markdown quality, code-block conventions, diagrams, and documentation maintenance expectations.
---

# Documentation Standards

## Content
- Write for the reader who has no prior context about the project
- Lead with the most important information
- Start maintained documents with a TL;DR callout summarising the page's purpose:
  `> [!IMPORTANT]`
  `> **TL;DR:** One concise paragraph describing what this page is for.`
- Use clear, concise language; avoid jargon without explanation
- Include practical examples for non-trivial concepts

## Structure
- Use a clear heading hierarchy (H1 for title, H2 for sections, H3 for subsections)
- Include a brief overview or purpose statement at the top
- Use bullet points and numbered lists for scanability
- Keep paragraphs short — 3 to 5 sentences maximum

## READMEs
- Include: project purpose, prerequisites, setup instructions, usage examples
- Add a quick-start section for common workflows
- Document environment variables and configuration options
- Keep setup instructions copy-paste ready

## Code Documentation
- Document public APIs with parameter descriptions and return types
- Include usage examples for non-obvious interfaces
- Document error conditions and edge cases
- Keep doc comments adjacent to the code they describe

## Code Blocks
- Always use a language tag on fenced code blocks — never use bare triple-backticks
- Use the correct tag for the content (`bash`, `python`, `json`, `yaml`, `sql`, `hcl`, `text`, etc.)
- Use `text` for log snippets, expected output, or non-executable content

## Diagrams
- Use Mermaid diagrams to visualise processes, system interactions, and architecture
- Choose the appropriate diagram type:
  - `flowchart TD` — processes, decision logic, deployment pipelines
  - `sequenceDiagram` — multi-system interactions, API flows, auth flows
  - `graph LR` — infrastructure topology, dependency maps
  - `stateDiagram-v2` — lifecycle states, incident workflows
- Place the diagram before the detailed explanation — visual first, then steps
- Keep diagrams focused: one concept per diagram, roughly 15 nodes maximum
- Label edges with the action or data being passed, not just arrows

## Domain Glossary
- Projects should maintain a glossary table mapping domain-specific terms, acronyms, and abbreviations to their definitions
- Place the glossary in the project README, a dedicated GLOSSARY.md, or the project's copilot-instructions file
- Format as a Markdown table with columns: Term, Definition, Context (optional)
- Keep entries alphabetised and update them as the domain evolves
- This helps AI assistants and new team members understand project-specific language without guessing

## Maintenance
- Update documentation alongside code changes
- Remove or update outdated documentation promptly
- Date or version-stamp architectural decision records
