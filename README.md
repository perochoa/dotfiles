# Dotfiles (local-first template)

> [!IMPORTANT]
> **TL;DR:** `~/.config/dotfiles` is the repository root for reproducible personal configuration. Track reusable config and templates, keep machine-local secrets/state out of git, and use `./bootstrap.sh` to wire symlinks and local files safely.

## Supported platforms

- **macOS** (Apple Silicon or Intel) with Homebrew
- **Fedora Linux** with native `dnf` packages plus [Homebrew on Linux](https://docs.brew.sh/Homebrew-on-Linux) for CLI tooling

Shell, tmux, Neovim, starship, and helper scripts detect the platform at runtime, so the same files work on both.

## Scope

Track only declarative, reusable config:

- shell, git, tmux, Homebrew, Neovim
- Copilot skills and non-secret Copilot settings
- templates for AWS and Kubernetes

Keep runtime state, machine caches, auth/session files, and private overrides local-only (ignored by `.gitignore`).

## Structure

- `shell/` — zsh modules plus `shell/zshrc` entrypoint (`env.zsh` → `aliases.zsh` → `functions.zsh` → `terminal.zsh` → optional untracked `zshrc.local`)
- `git/` — shared `config` (linked to `~/.config/git/config`) plus `gitconfig.local.template` for identity (copied to `gitconfig.local`, linked to `~/.gitconfig`)
- `tmux/` — canonical `tmux.conf`
- `homebrew/` — Brewfile (casks and macOS-only formulae are guarded by `OS.mac?`)
- `fedora/` — `packages.txt` of native Fedora packages installed with `dnf`
- `ghostty/` — Ghostty terminal config
- `nvim/` — shared Neovim configuration
- `bin/` — helper scripts (for example `awsme-sso.sh`, and `clip.sh` for a cross-platform clipboard)
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

1. Symlink `~/.zshrc`, `~/.gitconfig`, `~/.config/git/config`, `~/.tmux.conf`, `~/.config/starship.toml`, and `~/.config/nvim` to dotfiles-managed files.
2. Symlink `~/.copilot/skills` to the tracked Copilot skills in `copilot/`.
3. Symlink each script in `bin/` (without the `.sh` extension) into `~/.local/bin/` so they are on `$PATH`.
4. On Linux, symlink `~/.config/ghostty/config` to `ghostty/config` (on macOS, see [`ghostty/README.md`](ghostty/README.md)).
5. Create `git/gitconfig.local`, `aws/config.local` and `kube/config.eks.local.yaml` from tracked templates if missing.
6. Change your login shell to the system zsh if it isn't already (Fedora defaults to bash). It uses `chsh`, or `sudo usermod` if `chsh` isn't installed. Pass `--skip-shell` to opt out.
7. Note: bootstrap creates local templates but does not automatically scan for secrets. Run a secrets scanner (for example `detect-secrets` or `git-secrets`) and perform a git-history scan before publishing a public repo.

## Common workflows

Install or reconcile packages from this repo:

```bash
./scripts/install-apps.sh --dry-run
./scripts/install-apps.sh
```

On macOS this runs `brew bundle`. On Fedora it first installs `fedora/packages.txt` with `sudo dnf install`, then runs `brew bundle` (casks are skipped on Linux).

### Fedora setup

1. Install Homebrew on Linux: see <https://brew.sh> (installs to `/home/linuxbrew/.linuxbrew`; `shell/terminal.zsh` finds it automatically).
2. Run `./scripts/install-apps.sh`, then `./bootstrap.sh` (it switches your login shell to zsh; log out and back in afterwards).
3. Install the parts the Brewfile only provides as macOS casks:
   - **Ghostty**: see <https://ghostty.org/docs/install/binary> for the current Fedora package.
   - **Hack Nerd Font**: download it from <https://www.nerdfonts.com/font-downloads>, unzip it into `~/.local/share/fonts`, then run `fc-cache -f`.
   - **Copilot CLI**: `npm install -g @github/copilot`.

Apply your macOS defaults baseline (macOS only):

```bash
./scripts/macos-defaults.sh --dry-run
./scripts/macos-defaults.sh
```

## Local files (ignored)

- `*.local` (including `git/gitconfig.local` and `shell/zshrc.local`)
- `private/`
- `aws/config.local`
- `kube/config.eks.local.yaml`
- `kube/config.local`
- `copilot/config.json`
- `copilot/session-store.db*`
- `copilot/installed-plugins/`
- `copilot/language-servers/`

## Environment variables

Set by `shell/env.zsh` when the files exist:

- `AWS_CONFIG_FILE=~/.config/dotfiles/aws/config.local`
- `KUBECONFIG=~/.config/dotfiles/kube/config.eks.local.yaml:$HOME/.kube/config.local`
- `EDITOR`/`VISUAL=nvim`, `~/.local/bin` on `PATH`, and history settings (`~/.zsh_history`, 50k entries)

## Machine-specific overrides

- **Shell:** put per-machine zsh config in `shell/zshrc.local`; it's loaded last and ignored by git.
- **Git:** shared settings go in `git/config`. Identity and per-machine settings go in `git/gitconfig.local` (`~/.gitconfig`), which overrides the shared file. `git config --global` writes there, so the tracked config is never edited by tools.

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
