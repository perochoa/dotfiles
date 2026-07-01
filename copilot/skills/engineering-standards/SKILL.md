---
name: engineering-standards
description: Shared Mobility Global engineering standards and best practices. Use for communication norms, code-change expectations, commit workflow, project awareness, and repository-wide implementation standards.
---

# Engineering Standards & Global Instructions

You are working in a professional software engineering environment. Follow these principles in all interactions.

## Communication
- Never run any CLI command that mutates state without explicit confirmation.
- Never run commands that interact with external systems or services without explicit confirmation. This includes aws, kubectl, terraform, curl/wget to external URLs, podman pull/push to remote registries, and git push.
- Be concise and direct in explanations
- Show code changes rather than describing them
- When asked to implement something, do it — don't just suggest

## Code Changes
- Make precise, surgical changes that fully address the request
- Don't modify unrelated code
- Preserve existing code style and conventions of the project
- Run existing linters, tests, and builds after making changes
- Never commit code that doesn't compile or pass tests

## Architecture
- Favour composition over inheritance
- Use dependency injection for testability
- Follow the repository pattern for data access
- Use consistent API response envelopes with success, data, error, and pagination fields

## Quality Gates
- All code must be reviewed before merging
- Minimum 80% test coverage
- No hardcoded secrets or credentials
- All user input must be validated at system boundaries
- Handle errors at every level; never silently swallow them

## Git Workflow
- Before your first commit, check `git log --oneline -20` to detect the project's existing commit convention and match it
- Common conventions to recognise:
  - Conventional Commits (semantic-release): `feat(scope): description` or `feat: description`
  - Ticket-prefixed conventional: `feat ABC-123: description`
  - Ticket-first, plain English: `ABC-123: Add user login`
  - Ticket in trailer: subject line + `Refs: ABC-123` in the commit body
- If no convention is evident, default to conventional commits: `<type>: <description>`
- Valid conventional commit types: feat, fix, refactor, docs, test, chore, perf, ci
- Write atomic commits with a single logical change
- Push feature branches; never commit directly to main
- Never force push (`--force` or `-f`) to protected branches (main, master, develop, release/*). This is prohibited regardless of user confirmation.
- Split commits between refactoring / reformatting and actual task work

### Merge Request Review Workflow
- All merge requests must receive at least one code review pass before merging
- When creating an MR, write a clear description of the change, motivation, and relevant context or links to tickets
- Code review and implementation must happen in separate agent conversations to avoid confusion between suggesting improvements and implementing them
- Continue the review→fix cycle up to 3 iterations per MR until the code is clean and meets quality standards
- Always wait for human approval before merging

## AI Guardrails
- Never assume missing context — ask if uncertain rather than guessing
- Confirm file paths and module names exist before referencing them
- Never hallucinate libraries, packages, or APIs — only use known, verified dependencies
- If a task is ambiguous, clarify scope before writing code
- When suggesting a new dependency, verify it exists and is actively maintained
- Do not invent CLI flags, configuration keys, or API endpoints

## Cloud & Infrastructure
- Kubernetes work uses kubectl
- Prefer podman over Docker
- AWS CLI is configured; use profiles rather than inline credentials

## Project Awareness & Context

### LEARNING.md (committed — shared team knowledge)
- Lives in `.github/steering/LEARNING.md` and is committed to the repository.
- Read relevant sections at the start of a new conversation — match by domain tags or topic, not the whole file.
- When you discover something during work (explicit user instruction or your own exploration), add it to LEARNING.md with a brief description and today's date.
- Do not duplicate information that already exists in instruction files or agent definitions.

## MR Review After Push

After any `git push` to a branch with an open merge request, initiate the MR review workflow:

**Interactive mode**: Present the user with options — Review only / Review and fix / Skip. Never start a review without user confirmation.

**Non-interactive mode (autopilot/subagent)**: Automatically start a review-only pass. Post findings as MR comments. Do not make code changes unless explicitly requested.

Use the `gitlab-cli` skill for MR detection (`glab mr list --source-branch=<branch>`) and inline review comments. If you are the orchestrator, delegate to the code-reviewer agent instead.

# General Coding Standards

## Code Quality
- Write small, focused functions (< 50 lines) with a single responsibility
- Keep files under 800 lines; prefer many small files over few large ones
- Limit nesting depth to 4 levels maximum
- Use descriptive, intention-revealing names for variables, functions, and types
- Prefer immutability — create new objects rather than mutating existing ones
- Avoid magic numbers and hardcoded values; use named constants
- Remove dead code rather than commenting it out

## Error Handling
- Handle errors at every level; never silently swallow them
- Use specific error types over generic ones
- Provide clear, actionable error messages
- Log detailed context server-side; show user-friendly messages in UI code
- Fail fast with clear messages on invalid input

## Input Validation
- Validate all external input at system boundaries
- Use schema-based validation where available
- Never trust data from external sources without validation

## Code Organisation
- Organise code by feature or domain, not by type
- Aim for high cohesion within modules and low coupling between them
- Keep related code close together

## Version Control
- Write atomic commits with a single logical change
- Follow the project's existing commit convention — check `git log` to detect the pattern
- If no convention exists, use conventional commits: `<type>: <description>`
- Valid conventional commit types: feat, fix, refactor, docs, test, chore, perf, ci

## Method Naming Conventions
Use consistent verb prefixes that convey intent at a glance:
- `fetch*` / `get*` — retrieve data (use `fetch` for external/API calls, `get` for local/cached)
- `create*` / `build*` — construct new objects or resources
- `parse*` / `transform*` — convert data from one format to another
- `find*` / `extract*` — search within a collection or structure
- `validate*` / `check*` — verify correctness, return boolean or throw
- `handle*` / `on*` — respond to events, exceptions, or callbacks
- `provide*` / `supply*` — furnish context, dependencies, or configuration
- `update*` / `set*` — modify existing state or resources
- `delete*` / `remove*` — destroy or detach resources

## Documentation
- Document the "why", not the "what" — code should be self-explanatory
- Keep comments current; remove stale comments
- Add doc comments to public APIs and exported functions