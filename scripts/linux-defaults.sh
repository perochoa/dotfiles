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

[[ "$(uname -s)" == "Linux" ]] || error "This script only supports Linux."
command -v gsettings >/dev/null 2>&1 || error "gsettings not found; this script targets GNOME."

# Set a GNOME setting, skipping it if this GNOME version doesn't have it.
set_key() {
  local schema="$1" key="$2" value="$3"
  if ! gsettings writable "$schema" "$key" >/dev/null 2>&1; then
    warn "$schema $key not available; skipped"
  elif [[ "$DRY_RUN" == true ]]; then
    log "DRY RUN: gsettings set $schema $key $value"
  else
    gsettings set "$schema" "$key" "$value"
  fi
}

# Keyboard: fast key repeat (macOS KeyRepeat 1 = 15 ms)
set_key org.gnome.desktop.peripherals.keyboard repeat true
set_key org.gnome.desktop.peripherals.keyboard repeat-interval 15

# File chooser: folders before files (macOS _FXSortFoldersFirst), for GTK 4 and GTK 3 apps
set_key org.gtk.gtk4.Settings.FileChooser sort-directories-first true
set_key org.gtk.Settings.FileChooser sort-directories-first true

log "GNOME defaults applied."
