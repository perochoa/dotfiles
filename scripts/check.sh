#!/usr/bin/env bash
set -euo pipefail

# Validate the repo: lint scripts, syntax-check zsh, then bootstrap into a throwaway $HOME
# and confirm an interactive zsh starts cleanly. Used by CI on macOS and Fedora; safe to run locally.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() { echo "==> $*"; }
fail() {
  echo "FAIL: $*" >&2
  exit 1
}

cd "$ROOT_DIR"

bash_scripts() {
  printf '%s\n' bootstrap.sh scripts/*.sh bin/*.sh copilot/skills/*/scripts/*.sh
}

if command -v shellcheck >/dev/null 2>&1; then
  log "shellcheck"
  # shellcheck disable=SC2046 # word splitting of the file list is intended
  shellcheck -x -P SCRIPTDIR $(bash_scripts)
else
  log "shellcheck not installed; skipping lint"
fi

log "bash syntax"
for f in $(bash_scripts); do
  bash -n "$f" || fail "bash syntax: $f"
done

log "zsh syntax"
zsh -n shell/zshrc shell/*.zsh

# Fresh machine simulation: copy the repo (minus local-only files) into a temporary $HOME.
TEST_HOME="$(mktemp -d)"
trap 'rm -rf "$TEST_HOME"' EXIT
mkdir -p "$TEST_HOME/.config"
cp -R "$ROOT_DIR" "$TEST_HOME/.config/dotfiles"
find "$TEST_HOME/.config/dotfiles" -name '*.local' -delete

# Pre-existing configs with the same basename must both survive as backups.
mkdir -p "$TEST_HOME/.config/git" "$TEST_HOME/.config/ghostty"
echo old-git >"$TEST_HOME/.config/git/config"
echo old-ghostty >"$TEST_HOME/.config/ghostty/config"

log "bootstrap (fresh)"
HOME="$TEST_HOME" "$TEST_HOME/.config/dotfiles/bootstrap.sh" --skip-shell >/dev/null

log "backups"
for backup in .config/git/config:old-git .config/ghostty/config:old-ghostty; do
  grep -qx "${backup#*:}" "$TEST_HOME"/.backups/dotfiles/*/"${backup%%:*}" || fail "backup lost: ~/${backup%%:*}"
done

log "bootstrap (idempotent)"
rerun="$(HOME="$TEST_HOME" "$TEST_HOME/.config/dotfiles/bootstrap.sh" --skip-shell)"
if grep -E '^(Linking|Backing up)' <<<"$rerun"; then
  fail "second bootstrap run changed links"
fi

log "symlinks"
for link in .zshrc .gitconfig .config/git/config .tmux.conf .config/starship.toml .config/nvim \
  .config/ghostty/config .copilot/skills .local/bin/clip .local/bin/awsme-sso; do
  [[ -L "$TEST_HOME/$link" && -e "$TEST_HOME/$link" ]] || fail "missing or broken link: ~/$link"
done

log "git config layers"
[[ "$(HOME="$TEST_HOME" git config --global --get user.name)" == "John Doe" ]] || fail "identity not read from ~/.gitconfig"
[[ "$(HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_HOME/.config" git config --get alias.st)" == "status" ]] ||
  fail "shared aliases not read from ~/.config/git/config"

log "interactive zsh startup"
startup_output="$(cd "$TEST_HOME" && HOME="$TEST_HOME" TERM=xterm-256color zsh -i -c 'print -r -- "AWS=$AWS_CONFIG_FILE"' 2>&1)"
[[ "$startup_output" == "AWS=$TEST_HOME/.config/dotfiles/aws/config.local" ]] ||
  fail "zsh startup printed errors or did not set AWS_CONFIG_FILE:"$'\n'"$startup_output"

log "all checks passed"
