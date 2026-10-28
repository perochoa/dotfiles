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
  printf '%s\n' bootstrap.sh scripts/*.sh bin/*.sh ai/skills/*/scripts/*.sh
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
zsh -n shell/zshrc shell/*.zsh shell/zshrc.local.template

python_files() {
  printf '%s\n' ai/claude/hooks/*.py ai/skills/*/scripts/*.py
}

if command -v python3 >/dev/null 2>&1; then
  log "python syntax"
  # shellcheck disable=SC2046 # word splitting of the file list is intended
  python3 -c 'import ast, sys; [ast.parse(open(f).read(), f) for f in sys.argv[1:]]' $(python_files) ||
    fail "python syntax"
fi

# `ruff --version` instead of `command -v`: a pyenv shim exists even when the active env lacks ruff.
if ruff --version >/dev/null 2>&1; then
  log "ruff"
  # Pinned rule set (pyflakes + syntax errors) so results don't depend on the ruff version or user config.
  # shellcheck disable=SC2046 # word splitting of the file list is intended
  ruff check --quiet --isolated --no-cache --select E4,E7,E9,F $(python_files)
else
  log "ruff not installed; skipping python lint"
fi

# Fresh machine simulation: copy the repo into a temporary $HOME, then drop every git-ignored
# file (*.local, *.local.yaml, private/, ...) from the copy so templates are exercised.
TEST_HOME="$(mktemp -d)"
trap 'rm -rf "$TEST_HOME"' EXIT
mkdir -p "$TEST_HOME/.config"
cp -R "$ROOT_DIR" "$TEST_HOME/.config/dotfiles"
TEST_HOME="$(cd "$TEST_HOME" && pwd -P)"
[[ "$(git -C "$TEST_HOME/.config/dotfiles" rev-parse --show-toplevel)" == "$TEST_HOME/.config/dotfiles" ]] ||
  fail "repo copy does not resolve to its own worktree; refusing to git clean"
git -C "$TEST_HOME/.config/dotfiles" clean -fdXq

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
for link in \
  .agents/skills \
  .aws/config \
  .claude/CLAUDE.md \
  .claude/agents/architecture-auditor.md \
  .claude/hooks \
  .claude/settings.json \
  .claude/skills/gitlab-cli \
  .config/ghostty/config \
  .config/git/config \
  .config/nvim \
  .config/starship.toml \
  .copilot/copilot-instructions.md \
  .gitconfig \
  .local/bin/awsme-sso \
  .local/bin/clip \
  .tmux.conf \
  .zshrc; do
  [[ -L "$TEST_HOME/$link" && -e "$TEST_HOME/$link" ]] || fail "missing or broken link: ~/$link"
done

log "local files from templates"
for local in \
  aws/config.local \
  git/gitconfig.local \
  kube/config.eks.local.yaml \
  shell/zshrc.local; do
  [[ -f "$TEST_HOME/.config/dotfiles/$local" ]] || fail "not created from template: $local"
done

log "git config layers"
[[ "$(HOME="$TEST_HOME" git config --global --get user.name)" == "John Doe" ]] || fail "identity not read from ~/.gitconfig"
[[ "$(HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_HOME/.config" git config --get alias.st)" == "status" ]] ||
  fail "shared aliases not read from ~/.config/git/config"

log "interactive zsh startup"
startup_output="$(cd "$TEST_HOME" && HOME="$TEST_HOME" TERM=xterm-256color zsh -i -c 'print -r -- "AWS=$AWS_CONFIG_FILE"' 2>&1)"
[[ "$startup_output" == "AWS=$TEST_HOME/.config/dotfiles/aws/config.local" ]] ||
  fail "zsh startup printed errors or did not set AWS_CONFIG_FILE:"$'\n'"$startup_output"

# brew on PATH without HOMEBREW_PREFIX (e.g. PATH set by ~/.profile) must still load the zsh plugins
if command -v brew >/dev/null 2>&1 && [[ -d "$(brew --prefix)/share/zsh-syntax-highlighting" ]]; then
  log "zsh plugins without HOMEBREW_PREFIX"
  # shellcheck disable=SC2016 # expanded by the inner zsh
  highlighting="$(cd "$TEST_HOME" && env -u HOMEBREW_PREFIX HOME="$TEST_HOME" TERM=xterm-256color \
    PATH="$(dirname "$(command -v brew)"):/usr/bin:/bin" zsh -i -c 'print -r -- ${+ZSH_HIGHLIGHT_VERSION}' 2>&1)"
  [[ "$highlighting" == "1" ]] || fail "zsh-syntax-highlighting not loaded without HOMEBREW_PREFIX:"$'\n'"$highlighting"
fi

log "all checks passed"
