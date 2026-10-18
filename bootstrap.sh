#!/usr/bin/env bash
set -euo pipefail

# Create local files from templates, symlink dotfiles into $HOME, and make zsh the login shell.

usage() {
  cat <<'EOF'
Usage: bootstrap.sh [--dry-run] [--skip-shell]

Options:
  --dry-run     Print actions without changing files.
  --skip-shell  Do not change the login shell to zsh.
  -h, --help    Show this help.
EOF
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.backups/dotfiles/$(date +%Y%m%d%H%M%S)"
DRY_RUN=false
SKIP_SHELL=false

while [[ $# -gt 0 ]]; do
  case "$1" in
  --dry-run)
    DRY_RUN=true
    shift
    ;;
  --skip-shell)
    SKIP_SHELL=true
    shift
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    echo "Unknown argument: $1" >&2
    usage
    exit 1
    ;;
  esac
done

run() {
  if [[ "$DRY_RUN" == true ]]; then
    echo "DRY RUN: $*"
  else
    "$@"
  fi
}

# Copy a tracked template to its untracked local path unless it already exists.
copy_template() {
  local template="$ROOT_DIR/$1" local_file="$ROOT_DIR/$2"
  [[ -f "$local_file" ]] && return 0
  echo "Creating $2 from $1"
  run cp "$template" "$local_file"
}

# Symlink $HOME/<dst> to <src>, backing up anything already there under the same relative path.
link() {
  local src="$ROOT_DIR/$1" dst="$HOME/$2"
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    echo "OK: ~/$2"
    return 0
  fi
  if [[ -e "$dst" && ! -L "$dst" ]]; then
    echo "Backing up ~/$2 -> $BACKUP_DIR/$2"
    run mkdir -p "$(dirname "$BACKUP_DIR/$2")"
    run mv "$dst" "$BACKUP_DIR/$2"
  fi
  echo "Linking ~/$2 -> $1"
  run mkdir -p "$(dirname "$dst")"
  run ln -sfn "$src" "$dst"
}

copy_template git/gitconfig.local.template git/gitconfig.local
copy_template aws/config.template aws/config.local
copy_template kube/config.eks.template.yaml kube/config.eks.local.yaml
copy_template shell/zshrc.local.template shell/zshrc.local
copy_template ai/corrections.template.md ai/corrections.local.md

# Older layouts copied the shared git settings into the local file, where they shadow git/config.
if [[ -f "$ROOT_DIR/git/gitconfig.local" ]] && grep -qE '^\[(alias|fetch)\]' "$ROOT_DIR/git/gitconfig.local"; then
  echo "WARN: git/gitconfig.local has [alias]/[fetch] sections that override git/config; keep only [user] and machine-specific settings" >&2
fi

link shell/zshrc .zshrc
link git/gitconfig.local .gitconfig
link git/config .config/git/config
link tmux/tmux.conf .tmux.conf
link starship/starship.toml .config/starship.toml
link nvim .config/nvim
link ghostty/config .config/ghostty/config

# AI coding assistants share one set of instructions (ai/AGENTS.md) and skills (ai/skills).
# Remove links left behind by older layouts (copilot/, claude/) or by skills since deleted.
for stale in "$HOME/.copilot/skills" "$HOME"/.claude/skills/* "$HOME"/.claude/CLAUDE.md "$HOME"/.claude/settings.json; do
  if [[ -L "$stale" && ! -e "$stale" && "$(readlink "$stale")" == "$ROOT_DIR"/* ]]; then
    echo "Removing stale link ~/${stale#"$HOME"/}"
    run rm "$stale"
  fi
done
link ai/AGENTS.md .claude/CLAUDE.md
link ai/AGENTS.md .copilot/copilot-instructions.md
link ai/claude/settings.json .claude/settings.json
link ai/claude/hooks .claude/hooks
link ai/skills .agents/skills
# ~/.claude/skills also holds skills installed by Claude Code itself, so link each skill individually.
for skill in "$ROOT_DIR"/ai/skills/*/; do
  name="$(basename "$skill")"
  link "ai/skills/$name" ".claude/skills/$name"
done

# bin/ scripts go on PATH without their .sh extension
for script in "$ROOT_DIR"/bin/*.sh; do
  name="$(basename "$script" .sh)"
  link "bin/$name.sh" ".local/bin/$name"
done

# Make the system zsh the login shell (macOS defaults to zsh; Fedora defaults to bash).
ensure_zsh_login_shell() {
  local current zsh_path
  case "$(uname -s)" in
  Darwin) current="$(dscl . -read "/Users/$USER" UserShell | awk '{print $2}')" ;;
  *) current="$(getent passwd "$USER" | cut -d: -f7)" ;;
  esac

  if [[ "$(basename "$current")" == "zsh" ]]; then
    echo "OK: login shell is already $current"
    return 0
  fi

  # Prefer the system zsh: it is listed in /etc/shells and survives Homebrew changes.
  for zsh_path in /bin/zsh /usr/bin/zsh; do
    [[ -x "$zsh_path" ]] && break
  done
  if [[ ! -x "$zsh_path" ]]; then
    echo "WARN: zsh not found; install it (scripts/install-apps.sh) and re-run" >&2
    return 0
  fi
  if ! grep -qx "$zsh_path" /etc/shells; then
    echo "WARN: $zsh_path is not in /etc/shells; skipping login shell change" >&2
    return 0
  fi

  echo "Changing login shell: $current -> $zsh_path"
  if command -v chsh >/dev/null 2>&1; then
    run chsh -s "$zsh_path"
  else
    run sudo usermod --shell "$zsh_path" "$USER"
  fi
  [[ "$DRY_RUN" == true ]] || echo "Log out and back in for the new login shell to take effect."
}

if [[ "$SKIP_SHELL" == false ]]; then
  ensure_zsh_login_shell
fi

echo "Bootstrap complete."
