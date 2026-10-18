#!/usr/bin/env bash
set -euo pipefail

# Apply a reproducible baseline of GNOME desktop settings (Linux counterpart to macos-defaults.sh).
# Only settings with a GNOME equivalent are mirrored; GNOME already saves screenshots to ~/Pictures/Screenshots.

usage() {
  cat <<'EOF'
Usage: linux-defaults.sh [--dry-run]

Options:
  --dry-run  Print actions without changing settings.
  -h, --help Show this help.
EOF
}

DRY_RUN=false

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO  $*"; }
warn() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN  $*" >&2; }

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

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "This script only supports Linux." >&2
  exit 1
fi

if ! command -v gsettings >/dev/null 2>&1; then
  echo "gsettings not found; this script targets GNOME." >&2
  exit 1
fi

# Set a key only if its schema exists on this GNOME version.
set_key() {
  local schema="$1" key="$2" value="$3"
  if ! gsettings writable "$schema" "$key" >/dev/null 2>&1; then
    warn "$schema $key not available; skipped"
    return 0
  fi
  if [[ "$DRY_RUN" == true ]]; then
    log "DRY RUN: gsettings set $schema $key $value"
  else
    gsettings set "$schema" "$key" "$value"
  fi
}

# Keyboard: fast key repeat (macOS KeyRepeat 1 = 15 ms)
set_key org.gnome.desktop.peripherals.keyboard repeat true
set_key org.gnome.desktop.peripherals.keyboard repeat-interval 15

# Files: folders before files (macOS _FXSortFoldersFirst)
set_key org.gtk.gtk4.Settings.FileChooser sort-directories-first true
set_key org.gtk.Settings.FileChooser sort-directories-first true

log "GNOME defaults applied."
