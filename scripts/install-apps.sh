#!/usr/bin/env bash
set -euo pipefail

# Install Homebrew formulae and casks from the repo Brewfile.

usage() {
  cat <<'EOF'
Usage: install-apps.sh [--dry-run] [--file PATH]

Options:
  --dry-run   Validate Brewfile and report whether all entries are installed.
  --file PATH Use a specific Brewfile path (default: homebrew/Brewfile).
  -h, --help  Show this help.
EOF
}

log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO  $*"; }
error(){ echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR $*" >&2; exit 1; }

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BREWFILE_PATH="$ROOT_DIR/homebrew/Brewfile"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --file)
      [[ $# -ge 2 ]] || error "--file requires a path"
      BREWFILE_PATH="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      error "Unknown argument: $1"
      ;;
  esac
done

command -v brew >/dev/null 2>&1 || error "Homebrew is not installed."
[[ -f "$BREWFILE_PATH" ]] || error "Brewfile not found: $BREWFILE_PATH"

if [[ "$(uname -s)" != "Darwin" ]]; then
  error "This Brewfile contains macOS casks; run this installer on macOS."
fi

if [[ "$DRY_RUN" == true ]]; then
  log "Checking current system against Brewfile: $BREWFILE_PATH"
  if brew bundle check --file "$BREWFILE_PATH"; then
    log "All Brewfile dependencies are already installed."
  else
    log "Some Brewfile dependencies are missing. Re-run without --dry-run to install."
  fi
  exit 0
fi

log "Installing/updating packages from Brewfile: $BREWFILE_PATH"
brew bundle --file "$BREWFILE_PATH"
log "Homebrew bundle complete."
