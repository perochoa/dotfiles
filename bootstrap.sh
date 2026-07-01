#!/usr/bin/env bash
set -euo pipefail

# Wire standard dotfile symlinks, create local templates, and run a secrets guard.

usage() {
  cat <<'EOF'
Usage: bootstrap.sh [--dry-run]

Options:
  --dry-run  Print actions without changing files.
  -h, --help Show this help.
EOF
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.backups/dotfiles/$(date +%Y%m%d%H%M%S)"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
  --dry-run)
    DRY_RUN=true
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
  local backup="$BACKUP_DIR/$(basename "$dst").backup"

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
  local backup="$BACKUP_DIR/$(basename "$dst").backup"

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
link_file "$ROOT_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
link_file "$ROOT_DIR/starship/starship.toml" "$HOME/.config/starship.toml"
link_dir "$ROOT_DIR/nvim" "$HOME/.config/nvim"
link_dir "$ROOT_DIR/copilot/skills" "$HOME/.copilot/skills"

# Local bin scripts (strip .sh so they're callable without extension)
for _script in "$ROOT_DIR/bin/"*.sh; do
  [[ -f "$_script" ]] || continue
  _name="$(basename "${_script%.sh}")"
  link_file "$_script" "$HOME/.local/bin/$_name"
done

echo "Bootstrap complete."
