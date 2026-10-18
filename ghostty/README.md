# Applying Configuration

`./bootstrap.sh` symlinks `~/.config/ghostty/config` to `ghostty/config`. Ghostty reads that path on both macOS and Linux.

If an older setup added `config-file=.../dotfiles/ghostty/config` to `~/Library/Application Support/com.mitchellh.ghostty/config` on macOS, remove that line; bootstrap warns when it finds it.

Platform-specific keys (for example `macos-titlebar-style`) are ignored on other platforms. Keybindings use `super`, which is Cmd on macOS and the Super/Windows key on Linux.
