#!/usr/bin/env bash
set -euo pipefail

# Apply a reproducible baseline of macOS user defaults (Finder, Dock, screenshots, keyboard),
# then restart the apps that read them. linux-defaults.sh mirrors these on GNOME.

usage() {
  cat <<'EOF'
Usage: macos-defaults.sh [--dry-run]

Options:
  --dry-run  Print actions without changing settings.
  -h, --help Show this help.
EOF
}

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO  $*"; }
warn() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN  $*" >&2; }
error() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR $*" >&2
  exit 1
}

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
    usage >&2
    error "Unknown argument: $1"
    ;;
  esac
done

[[ "$(uname -s)" == "Darwin" ]] || error "This script only supports macOS."

# Run a command, or only print it with --dry-run.
run() {
  if [[ "$DRY_RUN" == true ]]; then
    log "DRY RUN: $*"
  else
    "$@"
  fi
}

SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
run mkdir -p "$SCREENSHOT_DIR"

# Finder: show extensions, path bar and status bar; folders before files
run defaults write -g AppleShowAllExtensions -bool true
run defaults write com.apple.finder ShowPathbar -bool true
run defaults write com.apple.finder ShowStatusBar -bool true
run defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Dock: auto-hide, no recent apps
run defaults write com.apple.dock autohide -bool true
run defaults write com.apple.dock show-recents -bool false

# Screenshots: PNG in ~/Pictures/Screenshots, no window shadow
run defaults write com.apple.screencapture location -string "$SCREENSHOT_DIR"
run defaults write com.apple.screencapture type -string png
run defaults write com.apple.screencapture disable-shadow -bool true

# Keyboard: fastest key repeat, no accent popup on press-and-hold
run defaults write -g KeyRepeat -int 1
run defaults write -g ApplePressAndHoldEnabled -bool false

# Restart the apps that cache these settings so they take effect now.
for app in Finder Dock SystemUIServer; do
  if [[ "$DRY_RUN" == true ]]; then
    log "DRY RUN: would restart $app"
  elif pgrep -x "$app" >/dev/null 2>&1; then
    killall "$app"
  else
    warn "$app not running; restart skipped"
  fi
done

log "macOS defaults applied."
