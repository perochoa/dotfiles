# Applying Configuration

- **Linux**: `./bootstrap.sh` symlinks `~/.config/ghostty/config` to `ghostty/config`.
- **macOS**: manually add `config-file=PATH_TO_DOTFILES/ghostty/config` to the local Ghostty config at `~/Library/Application Support/com.mitchellh.ghostty/config`.

Platform-specific keys (for example `macos-titlebar-style`) are ignored on other platforms. Keybindings use `super`, which is Cmd on macOS and the Super/Windows key on Linux.
