---
name: shell-patterns
description: Shell scripting guidance and standards. Use for bash safety, argument handling, idempotency, and portability expectations.
---

# Shell Scripting Patterns & Standards

## Script Header
- Always start scripts with `#!/usr/bin/env bash`
- Enable safe defaults: `set -euo pipefail`
- Include a brief comment describing the script's purpose

## Logging
- Include a timestamped log function for scripts that run unattended:
  ```bash
  log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO  $*"; }
  warn() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN  $*" >&2; }
  error(){ echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR $*" >&2; exit 1; }
  ```

## Arguments and Usage
- Include a `usage()` function and argument parsing (`getopts`) in non-trivial scripts
- Validate required arguments early; fail with a clear message if missing

## Style and Safety
- Quote all variable expansions: `"$var"`, not `$var`
- Use `[[ ]]` for conditionals, not `[ ]`
- Use `UPPER_CASE` for environment/config variables, `lower_case` for local variables
- Use meaningful, descriptive variable names
- Prefer built-in shell features over external commands where practical

## Idempotency
- Write operations that are safe to run more than once
- Guard state-changing operations with pre-condition checks (e.g., `[[ -f /path ]] || do_thing`)
- Add a `--dry-run` flag to scripts that modify system state

## Error Handling
- Always check exit codes on critical commands
- Never silently swallow errors
- Use `trap` for cleanup on exit when temporary files or resources are involved

## Portability
- Use `#!/usr/bin/env bash` for portability across systems
- When POSIX compatibility matters, avoid bash-specific features and note the requirement
- Never hardcode credentials, IPs, or environment-specific values — use variables or config files

## Anti-Patterns
- Never use `for line in $(command)` — use `while read -r line` with a process substitution or pipe
- Avoid parsing `ls` output — use glob patterns or `find` instead
- Do not rely on shell aliases in scripts — they are not available in non-interactive shells