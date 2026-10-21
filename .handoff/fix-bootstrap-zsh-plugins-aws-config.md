# fix/bootstrap-zsh-plugins-aws-config

## Goal
Fix two problems seen after bootstrapping another machine: zsh syntax highlighting/autocomplete not
loading, and no `~/.aws/config`.

## Status
- [x] env.zsh runs `brew shellenv` whenever HOMEBREW_PREFIX is unset (not only when brew is off PATH)
- [x] bootstrap links `~/.aws/config` -> `aws/config.local`
- [x] check.sh: `.aws/config` link + plugin load test without HOMEBREW_PREFIX (fails without the fix)
- [ ] user re-runs bootstrap + opens a new shell on the other machine to confirm
- [x] pushed, pr #11 opened

## Decisions
- Root cause (reproduced here, not yet confirmed on the other machine): brew on PATH but
  HOMEBREW_PREFIX unset (e.g. PATH set by ~/.profile or a parent shell) skipped shellenv, so
  terminal.zsh's plugin search had no Homebrew dir. `$commands[brew]` is tried first so a brew
  already on PATH wins.
- Kept the AWS_CONFIG_FILE export: the link points at the same file and covers tools not started
  from zsh; removing the export wasn't needed.

## Gotchas
- If the other machine never ran scripts/install-apps.sh, the plugins aren't installed at all and
  this fix won't help: `brew bundle check --file homebrew/Brewfile`.
- git-guard counts the branch prefix toward the subject length limit; keep the text after the
  prefix short.

## Key files
shell/env.zsh, shell/terminal.zsh, bootstrap.sh, scripts/check.sh
