#!/usr/bin/env bash
set -euo pipefail

# Install Homebrew formulae and casks from the repo Brewfile.
# On Fedora, first installs native prerequisites from fedora/packages.txt with dnf.

usage() {
  cat <<'EOF'
Usage: install-apps.sh [--dry-run] [--file PATH]

Options:
  --dry-run   Report missing Fedora packages (Linux) and Brewfile entries without installing.
  --file PATH Use a specific Brewfile path (default: homebrew/Brewfile).
  -h, --help  Show this help.
EOF
}

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO  $*"; }
warn() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN  $*" >&2; }
error() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR $*" >&2
  exit 1
}

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
  -h | --help)
    usage
    exit 0
    ;;
  *)
    error "Unknown argument: $1"
    ;;
  esac
done

FEDORA_PACKAGES_PATH="$ROOT_DIR/fedora/packages.txt"

install_fedora_packages() {
  [[ -f "$FEDORA_PACKAGES_PATH" ]] || error "Fedora package list not found: $FEDORA_PACKAGES_PATH"

  local packages=() missing=() pkg
  while read -r pkg; do
    packages+=("$pkg")
  done < <(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' "$FEDORA_PACKAGES_PATH")

  for pkg in "${packages[@]}"; do
    rpm -q "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
  done

  if [[ ${#missing[@]} -eq 0 ]]; then
    log "All Fedora packages are already installed."
  elif [[ "$DRY_RUN" == true ]]; then
    log "Missing Fedora packages: ${missing[*]}"
  else
    log "Installing Fedora packages: ${missing[*]}"
    sudo dnf install -y "${missing[@]}"
  fi
}

case "$(uname -s)" in
Darwin) ;;
Linux)
  [[ -r /etc/fedora-release ]] || error "Only Fedora is supported on Linux."
  command -v dnf >/dev/null 2>&1 || error "dnf not found."
  install_fedora_packages
  ;;
*)
  error "Unsupported OS: $(uname -s)"
  ;;
esac

if ! command -v brew >/dev/null 2>&1; then
  for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    if [[ -x "$brew_bin" ]]; then
      eval "$("$brew_bin" shellenv)"
      break
    fi
  done
fi
command -v brew >/dev/null 2>&1 || error "Homebrew is not installed. See https://brew.sh"
[[ -f "$BREWFILE_PATH" ]] || error "Brewfile not found: $BREWFILE_PATH"

if [[ "$DRY_RUN" == true ]]; then
  log "Checking current system against Brewfile: $BREWFILE_PATH"
  if brew bundle check --file "$BREWFILE_PATH"; then
    log "All Brewfile dependencies are already installed."
  else
    log "Some Brewfile dependencies are missing. Re-run without --dry-run to install."
  fi
else
  log "Installing/updating packages from Brewfile: $BREWFILE_PATH"
  brew bundle --file "$BREWFILE_PATH"
  log "Homebrew bundle complete."
fi

# Linux counterparts of the Brewfile's macOS-only casks. Failures warn instead of aborting.
install_linux_extras() {
  if fc-list 2>/dev/null | grep -qi "Hack Nerd Font"; then
    log "Hack Nerd Font is already installed."
  elif [[ "$DRY_RUN" == true ]]; then
    log "DRY RUN: would install Hack Nerd Font to ~/.local/share/fonts/HackNerdFont"
  else
    local font_dir="$HOME/.local/share/fonts/HackNerdFont"
    log "Installing Hack Nerd Font to $font_dir"
    mkdir -p "$font_dir"
    if curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.tar.xz | tar -xJ -C "$font_dir"; then
      fc-cache -f "$font_dir" >/dev/null
    else
      warn "Hack Nerd Font download failed; install it manually from https://www.nerdfonts.com/font-downloads"
    fi
  fi

  if command -v copilot >/dev/null 2>&1; then
    log "Copilot CLI is already installed."
  elif ! command -v npm >/dev/null 2>&1; then
    warn "npm not found; skipping Copilot CLI (node comes from the Brewfile)"
  elif [[ "$DRY_RUN" == true ]]; then
    log "DRY RUN: would run npm install -g @github/copilot"
  else
    log "Installing Copilot CLI with npm"
    npm install -g @github/copilot || warn "Copilot CLI install failed"
  fi

  command -v ghostty >/dev/null 2>&1 ||
    warn "Ghostty is not installed; it is not in the Fedora repos (see README for COPR options)"
}

if [[ "$(uname -s)" == "Linux" ]]; then
  install_linux_extras
fi
