# Neovim (LazyVim) - Developer Profile

This Neovim config is managed from `~/.config/dotfiles/nvim` and symlinked to
`~/.config/nvim` by `bootstrap.sh`.

## What's enabled

- **Language/tooling extras:** TypeScript, Python, Go, JSON, YAML, TOML, SQL, Docker, Terraform, Git.
- **Developer workflows:** test runner (`neotest` via LazyVim test extra), DAP core, rename/refactor extras, project utilities.
- **Formatting/linting extras:** Prettier and ESLint integrations, with Mason-aware Prettier/JQ commands and `jq` fallback for JSON/JSON5 formatting (including when Node is unavailable for Prettier).
- **Custom additions:** Fugitive Git commands and Neo-tree CWD sync behavior.
- **Tool installs via Mason:** common formatters/linters/debuggers (`prettier`, `eslint_d`, `black`, `debugpy`, `delve`, etc.).
- **Host-aware Mason behavior:** Go-based tools are only enforced when `go` is on `PATH`; Python pip-backed tools are skipped when a CodeArtifact-only pip index is detected without usable credentials.

## Useful custom keys

- `<leader>gg` - open Fugitive Git status
- `<leader>gB` - open Fugitive blame
- `<leader>w` - write buffer
- `<leader>qq` - quit all windows
- `<leader>rn` - rename current word in current buffer

For base keymaps and commands, see LazyVim docs:
<https://lazyvim.github.io/>

Detailed usage guide:
`DEVELOPER_GUIDE.md`
