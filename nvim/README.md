# Neovim (LazyVim)

[LazyVim](https://lazyvim.github.io/) config, linked to `~/.config/nvim`. Extras are enabled in `lazyvim.json`; custom config is in `lua/`.

Commit `lazy-lock.json` after `:Lazy update`; run `:Lazy restore` after pulling.

## Custom keys

| Key                       | Action                                                  |
| ------------------------- | ------------------------------------------------------- |
| `<leader>e`, `<leader>fe` | Explorer in its last directory                          |
| `<leader>gg`              | LazyGit in the explorer's directory (`<leader>gG`: cwd) |
| `<C-/>`                   | Terminal in the explorer's directory                    |
| `<leader>w`               | Write buffer                                            |
| `<leader>rn`              | Replace the word under the cursor in the buffer         |
| `J` / `K` (visual)        | Move selection down / up                                |
| `x` / `d` (explorer)      | Move / delete file                                      |

Go tools are installed only when `go` is on `PATH`, and pip-based tools are skipped behind an AWS CodeArtifact index. If a language feature is missing, check `:Mason` and `:checkhealth`.
