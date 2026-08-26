# Neovim (LazyVim) - Developer Profile

This Neovim config is managed from `~/.config/dotfiles/nvim` and symlinked to
`~/.config/nvim` by `bootstrap.sh`.

## What's enabled

- **Language/tooling extras:** TypeScript, Python, Go, JSON, YAML, TOML, SQL, Docker, Terraform, Git.
- **Developer workflows:** test runner (`neotest` via LazyVim test extra), DAP core, rename/refactor extras, project utilities.
- **Formatting/linting extras:** LazyVim's native Conform, Prettier, and ESLint integrations.
- **Git workflow:** LazyGit integration through Snacks and LazyVim.
- **File navigation:** Snacks Explorer and Snacks Picker.
- **Tool installs via Mason:** common formatters/linters/debuggers (`prettier`, `eslint_d`, `black`, `debugpy`, `delve`, etc.).
- **Host-aware Mason behavior:** Go-based tools are only enforced when `go` is on `PATH`; Python pip-backed tools are skipped when a CodeArtifact-only pip index is detected without usable credentials.

## Useful custom keys

- `<leader>gg` - open LazyGit at the project root
- `<leader>gG` - open LazyGit in the current working directory
- `<leader>w` - write buffer
- `<leader>qq` - quit all windows
- `<leader>rn` - rename current word in current buffer

For base keymaps and commands, see LazyVim docs:
<https://lazyvim.github.io/>

Detailed usage guide:
`DEVELOPER_GUIDE.md`
