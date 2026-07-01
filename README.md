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
2. Symlink `~/.copilot/skills` to the tracked Copilot skills in `copilot/`.
3. Symlink each script in `bin/` (without the `.sh` extension) into `~/.local/bin/` so they are on `$PATH`.
4. Create `aws/config.local` and `kube/config.eks.local.yaml` from tracked templates if missing.
5. Note: bootstrap creates local templates but does not automatically scan for secrets. Run a secrets scanner (for example `detect-secrets` or `git-secrets`) and perform a git-history scan before publishing a public repo.

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
- Bootstrap creates local templates but does not run an automatic secrets scanner. Before publishing, run a secrets scanner (for example `detect-secrets` or `git-secrets`) and review git history for any committed secrets or PII.

## Public repository checklist (before publishing)

- Ensure all `*.local` files are templates or removed from the repository (examples: `aws/config.local`, `kube/config.eks.local.yaml`).
- Remove tracked local-only files from the index (git rm --cached <file>) and commit templates instead.
- Run a history scan for secrets and PII (for example: `git log --all -S "AKIA\|ghp_\|AWS_SECRET_ACCESS_KEY"` and `detect-secrets scan --baseline .secrets.baseline`).
- If secrets were ever committed, rotate credentials immediately and rewrite history (git-filter-repo or BFG) before publishing.
- Consider adding an automated pre-push/CI secret check to block accidental leaks.
