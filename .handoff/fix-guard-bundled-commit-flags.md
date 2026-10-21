# fix/guard-bundled-commit-flags

## Goal
git-guard.py misread `git commit -qm "<subject>" -m "<body>"`: it ignored the bundled `-qm`, took
the body as the whole message, and rejected it (no prefix, 204-char subject).

## Status
- [x] `commit_options()` parses commit options like git: bundled short flags (`-qm`, `-aqF -`,
      `-qmvalue`), long `--opt value` / `--opt=value`, option values not rescanned as options
- [x] check.sh cases (fail on the old hook); `./scripts/check.sh` passes
- [x] pushed; no PR opened yet (open one when the user asks)

## Decisions
- The `-m` values were already joined with a blank line; the bug was option parsing, not joining.
- Value-taking short flags: `m F c C t`; `S u` take only an attached value, so they end the bundle.
- Branch is named without "git" because the worktree-isolation check rejects commands that
  mention git more than once.

## Gotchas
- `~/.claude/hooks` links to the main checkout, so the fix is live only once that checkout has it.

## Key files
- `ai/claude/hooks/git-guard.py`, `scripts/check.sh`
