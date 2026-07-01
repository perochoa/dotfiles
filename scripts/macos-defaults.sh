#!/usr/bin/env bash
set -euo pipefail

# Apply a reproducible baseline of macOS user defaults.

usage() {
  cat <<'EOF'
Usage: macos-defaults.sh [--dry-run]

Options:
  --dry-run  Print actions without changing settings.
  -h, --help Show this help.
EOF
}

DRY_RUN=false

log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO  $*"; }
warn() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN  $*" >&2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
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

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script only supports macOS." >&2
  exit 1
fi

run_cmd() {
  local command=("$@")
  if [[ "$DRY_RUN" == true ]]; then
    log "DRY RUN: ${command[*]}"
  else
    "${command[@]}"
  fi
}

SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
run_cmd mkdir -p "$SCREENSHOT_DIR"

# Finder behavior
run_cmd defaults write NSGlobalDomain AppleShowAllExtensions -bool true
run_cmd defaults write com.apple.finder ShowPathbar -bool true
run_cmd defaults write com.apple.finder ShowStatusBar -bool true
run_cmd defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Dock behavior
run_cmd defaults write com.apple.dock autohide -bool true
run_cmd defaults write com.apple.dock show-recents -bool false

# Screenshot defaults
run_cmd defaults write com.apple.screencapture location -string "$SCREENSHOT_DIR"
run_cmd defaults write com.apple.screencapture type -string png
run_cmd defaults write com.apple.screencapture disable-shadow -bool true

if [[ "$DRY_RUN" == true ]]; then
  log "DRY RUN: would restart Finder, Dock, and SystemUIServer"
else
  for process_name in Finder Dock SystemUIServer; do
    if pgrep -x "$process_name" >/dev/null 2>&1; then
      run_cmd killall "$process_name"
    else
      warn "$process_name not running; restart skipped"
    fi
  done
fi

log "macOS defaults applied."
