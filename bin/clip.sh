#!/usr/bin/env bash
set -euo pipefail

# Copy stdin to the system clipboard on macOS or Linux (Wayland/X11).
# Falls back to an OSC 52 escape sequence so terminals like Ghostty/tmux can
# still receive the selection over SSH or when no clipboard tool is installed.

if command -v pbcopy >/dev/null 2>&1; then
  exec pbcopy
elif [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v wl-copy >/dev/null 2>&1; then
  exec wl-copy
elif [[ -n "${DISPLAY:-}" ]] && command -v xclip >/dev/null 2>&1; then
  exec xclip -selection clipboard
elif [[ -n "${DISPLAY:-}" ]] && command -v xsel >/dev/null 2>&1; then
  exec xsel --clipboard --input
fi

printf '\e]52;c;%s\a' "$(base64 | tr -d '\n')" >/dev/tty
