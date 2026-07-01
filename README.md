# Dotfiles (local-first template)

> [!IMPORTANT]
> **TL;DR:** `~/.config/dotfiles` is the repository root for reproducible personal configuration. Track reusable config and templates, keep machine-local secrets/state out of git, and use `./bootstrap.sh` to wire symlinks and local files safely.

## Scope

Track only declarative, reusable config:

- shell, git, tmux, Homebrew, Neovim
- Copilot skills and non-secret Copilot settings
- templates for AWS and Kubernetes

Keep runtime state, machine caches, auth/session files, and private overrides local-only (ignored by `.gitignore`).

## Structure

- `shell/` — zsh modules plus `shell/zshrc` entrypoint
- `git/` — canonical `gitconfig`
- `tmux/` — canonical `tmux.conf`
- `homebrew/` — Brewfile
- `nvim/` — shared Neovim configuration
- `bin/` — helper scripts (for example `awsme-sso.sh`)
- `copilot/` — portable Copilot settings and skills
- `aws/` — tracked template + local runtime config
- `kube/` — tracked template + local EKS config
- `scripts/` — bootstrap and validation helpers

## Quick start

```bash
cd ~/.config/dotfiles
./bootstrap.sh
```

This will:

1. Symlink `~/.zshrc`, `~/.gitconfig`, `~/.tmux.conf`, and `~/.config/nvim` to dotfiles-managed files.
2. Symlink `~/.copilot/settings.json`, `~/.copilot/lsp-config.json`, and `~/.copilot/skills` to the tracked Copilot config in `copilot/`.
3. Symlink each script in `bin/` (without the `.sh` extension) into `~/.local/bin/` so they are on `$PATH`.
4. Create `aws/config.local` and `kube/config.eks.local.yaml` from tracked templates if missing.
5. Run a basic secrets guard against tracked-style files.

## Common workflows

Install or reconcile Homebrew packages from this repo:

```bash
./scripts/install-apps.sh --dry-run
./scripts/install-apps.sh
```

> [!NOTE]
> `scripts/install-apps.sh` currently targets macOS because this Brewfile includes casks.

Apply your macOS defaults baseline:

```bash
./scripts/macos-defaults.sh --dry-run
./scripts/macos-defaults.sh
```

## Local files (ignored)

- `*.local`
- `private/`
- `aws/config.local`
- `kube/config.eks.local.yaml`
- `kube/config.local`
- `copilot/config.json`
- `copilot/session-store.db*`
- `copilot/installed-plugins/`
- `copilot/language-servers/`

## Environment variables

- `AWS_CONFIG_FILE=~/.config/dotfiles/aws/config.local`
- `KUBECONFIG=~/.config/dotfiles/kube/config.eks.local.yaml:$HOME/.kube/config.local`

## Homebrew policy

See [`homebrew/Brewfile.lock.md`](homebrew/Brewfile.lock.md) for what is intentionally excluded from `Brewfile` to avoid machine-specific drift.

## Safety notes

- Do not commit local secrets, auth caches, or machine-generated state.
- Run `scripts/secrets-check.sh` before commit if you bypass `bootstrap.sh`.
