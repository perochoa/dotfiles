# LazyVim Developer Guide

This guide explains what was added to this Neovim profile and how to use it effectively for development work.

## What was added

### 1. Developer extras (LazyVim)

Enabled via `lazyvim.json`:

- DAP core (debugging)
- Test core (neotest)
- Incremental rename + refactoring
- Snacks Explorer and Snacks Picker
- Treesitter context
- Project utilities
- Prettier + ESLint integrations
- Language packs for:
  - Go
  - Python
  - TypeScript
  - JSON
  - YAML
  - TOML
  - SQL
  - Docker
  - Terraform
  - Git

### 2. Plugins added in `lua/plugins/example.lua`

- Trouble diagnostics signs enabled
- Extended Mason tool installation set
- Extended Treesitter parser coverage

### 3. Editor ergonomics

In `lua/config/options.lua`:

- relative line numbers
- always-on sign column
- no line wrap by default
- better viewport context (`scrolloff`, `sidescrolloff`)
- faster update interval
- split right / split below behavior

### 4. Keymaps added

In `lua/config/keymaps.lua`:

- `<leader>w` — save current buffer
- `<leader>qq` — quit all windows
- `<leader>rn` — rename current word in current buffer
- Visual mode:
  - `J` — move selected block down
  - `K` — move selected block up

Also from plugin mappings:

- `<leader>gg` — LazyGit at the project root
- `<leader>gG` — LazyGit in the current working directory
---

## How to use it to the fullest

## A) Daily loop

1. Open a project root (where language config files exist).
2. Let LSP auto-attach for the filetype.
3. Use diagnostics + quickfix navigation.
4. Run tests close to the code you’re editing.
5. Debug only when tests/logging are insufficient.

## B) Test workflow

Use LazyVim’s test keymaps under `<leader>t`:

- nearest test
- current file tests
- full suite
- watch mode
- output panel

Tip: start with nearest test while iterating.

## C) Debug workflow

Use `<leader>d` actions:

- toggle/set breakpoints
- start/continue debug session
- step into/over/out
- inspect variables/scopes

Tip: combine with test workflow for precise repro + step-through.

## D) Refactor safely

- Use LSP rename/refactor actions under `<leader>c...`
- Use `<leader>rn` for fast in-buffer rename when a full-symbol rename is unnecessary
## E) Git flow in editor

- `<leader>gg`: open LazyGit at the project root
- `<leader>gG`: open LazyGit in the current working directory
- keep diagnostics visible with Trouble for code-quality pass before commit

---

## Host-aware Mason behavior (important)

This setup avoids repeated install failures on this host:

- Go-based tools (`gopls`, `goimports`, `gofumpt`, `delve`) are only enforced if `go` exists in `PATH`.
- Python pip-backed tools (`black`, `debugpy`, `ruff`, `sqlfluff`) are skipped when a CodeArtifact-only pip index is detected without usable credentials.

This keeps the editor stable while still enabling all non-blocked tooling.

---

## Useful commands

- `:Lazy` — plugin manager UI
- `:Lazy sync` — sync plugin set
- `:Mason` — inspect/install external tools
- `:checkhealth` — general health checks

If a language feature seems missing, check `:Mason` and confirm required system runtimes are installed (`go`, `python`, `node`, etc.).
