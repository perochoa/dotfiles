#!/usr/bin/env bash
set -euo pipefail

# Wire standard dotfile symlinks, create local templates, and run a secrets guard.

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

link_file() {
  local src="$1"
  local dst="$2"
  local backup
  backup="$BACKUP_DIR/$(basename "$dst").backup"

  if [[ -L "$dst" ]]; then
    if [[ "$(readlink "$dst")" == "$src" ]]; then
      echo "OK: $dst already linked"
      return 0
    fi
  elif [[ -e "$dst" ]]; then
    echo "Backing up $dst -> $backup"
    if [[ "$DRY_RUN" == false ]]; then
      mkdir -p "$BACKUP_DIR"
      mv "$dst" "$backup"
    fi
  fi

  echo "Linking $dst -> $src"
  if [[ "$DRY_RUN" == false ]]; then
    ln -sfn "$src" "$dst"
  fi
}

link_dir() {
  local src="$1"
  local dst="$2"
  local backup
  backup="$BACKUP_DIR/$(basename "$dst").backup"

  if [[ -L "$dst" ]]; then
    if [[ "$(readlink "$dst")" == "$src" ]]; then
      echo "OK: $dst already linked"
      return 0
    fi
  elif [[ -d "$dst" ]]; then
    echo "Backing up $dst -> $backup"
    if [[ "$DRY_RUN" == false ]]; then
      mkdir -p "$BACKUP_DIR"
      mv "$dst" "$backup"
    fi
  elif [[ -e "$dst" ]]; then
    echo "Cannot replace non-directory path: $dst" >&2
    exit 1
  fi

  echo "Linking $dst -> $src"
  if [[ "$DRY_RUN" == false ]]; then
    ln -sfn "$src" "$dst"
  fi
}

if [[ "$DRY_RUN" == false ]]; then
  "$ROOT_DIR/scripts/bootstrap-local.sh"
else
  echo "DRY RUN: would run scripts/bootstrap-local.sh"
fi

if [[ "$DRY_RUN" == false ]]; then
  chmod +x "$ROOT_DIR/scripts/bootstrap-local.sh"
  mkdir -p "$HOME/.config"
  mkdir -p "$HOME/.copilot"
  mkdir -p "$HOME/.local/bin"
else
  echo "DRY RUN: would create $HOME/.config, $HOME/.copilot, $HOME/.local/bin if missing"
  echo "DRY RUN: backups would go to $BACKUP_DIR"
fi

link_file "$ROOT_DIR/shell/zshrc" "$HOME/.zshrc"
link_file "$ROOT_DIR/git/gitconfig.local" "$HOME/.gitconfig"
[[ "$DRY_RUN" == false ]] && mkdir -p "$HOME/.config/git"
link_file "$ROOT_DIR/git/config" "$HOME/.config/git/config"
link_file "$ROOT_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
link_file "$ROOT_DIR/starship/starship.toml" "$HOME/.config/starship.toml"
link_dir "$ROOT_DIR/nvim" "$HOME/.config/nvim"
link_dir "$ROOT_DIR/copilot/skills" "$HOME/.copilot/skills"

# Ghostty reads ~/.config/ghostty/config on both macOS and Linux.
[[ "$DRY_RUN" == false ]] && mkdir -p "$HOME/.config/ghostty"
link_file "$ROOT_DIR/ghostty/config" "$HOME/.config/ghostty/config"

# Older setups included the repo config from macOS's Application Support file; that would now load it twice.
ghostty_macos_config="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
if [[ -f "$ghostty_macos_config" ]] && grep -q '^config-file *=.*dotfiles/ghostty/config' "$ghostty_macos_config"; then
  echo "WARN: remove the dotfiles config-file line from $ghostty_macos_config (now loaded from ~/.config/ghostty/config)" >&2
fi

# Local bin scripts (strip .sh so they're callable without extension)
for _script in "$ROOT_DIR/bin/"*.sh; do
  [[ -f "$_script" ]] || continue
  _name="$(basename "${_script%.sh}")"
  link_file "$_script" "$HOME/.local/bin/$_name"
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
  if [[ "$DRY_RUN" == true ]]; then
    return 0
  fi
  if command -v chsh >/dev/null 2>&1; then
    chsh -s "$zsh_path"
  else
    sudo usermod --shell "$zsh_path" "$USER"
  fi
  echo "Log out and back in for the new login shell to take effect."
}

if [[ "$SKIP_SHELL" == false ]]; then
  ensure_zsh_login_shell
fi

echo "Bootstrap complete."
