# Neovim (LazyVim)

Managed from `~/.config/dotfiles/nvim` and symlinked to `~/.config/nvim` by `bootstrap.sh`. Base keymaps and commands are LazyVim's: <https://lazyvim.github.io/>.

## Layout

- `lazyvim.json` — enabled LazyVim extras: DAP, tests (neotest), inc-rename, refactoring, Snacks explorer/picker, treesitter-context, project, Prettier, ESLint, and language packs for Go, Python, TypeScript, JSON, YAML, TOML, SQL, Docker, Terraform, Markdown, Git.
- `lua/config/` — options (`scrolloff = 8`) and custom keymaps.
- `lua/plugins/colorscheme.lua` — Tokyo Night (night, transparent).
- `lua/plugins/snacks.lua` — explorer tweaks: remembers its last directory, `x` moves and `d` deletes files.
- `lua/plugins/tooling.lua` — extra Mason tools, the `jsonc` Treesitter parser (LazyVim and the extras cover the rest), and Trouble signs.
- `lazy-lock.json` — pinned plugin versions. Commit it after `:Lazy update`; run `:Lazy restore` after pulling.

## Custom keys

| Key | Action |
| --- | --- |
| `<leader>e`, `<leader>fe` | Snacks explorer in its last directory |
| `<leader>gg` | LazyGit in the explorer's directory (`<leader>gG`: current working directory) |
| `<C-/>` | Terminal in the explorer's directory |
| `<leader>w` | Write buffer |
| `<leader>rn` | Replace the word under the cursor throughout the buffer |
| `J` / `K` (visual) | Move selection down / up |

## Host-aware tooling

`tooling.lua` adapts Mason and LSP to the machine:

- Go tools (`gopls`, `goimports`, `gofumpt`, `delve`) are only installed when `go` is on `PATH`.
- pip-based tools (`black`, `debugpy`, `ruff`, `sqlfluff`) are skipped when pip points at an AWS CodeArtifact index, where they fail to install without credentials.

If a language feature is missing, check `:Mason` and `:checkhealth`, and make sure the runtime (`go`, `python`, `node`) is installed.
