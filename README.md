# Dotfiles

Config for macOS and Fedora, kept at `~/.config/dotfiles`. Secrets and machine-specific settings live in untracked `*.local` files.

## Setup

```bash
git clone https://github.com/perochoa/dotfiles ~/.config/dotfiles
cd ~/.config/dotfiles
./scripts/install-apps.sh   # packages (--dry-run to preview)
./bootstrap.sh              # local files, symlinks, login shell (--dry-run to preview)
```

`bootstrap.sh` is safe to re-run. It creates missing `*.local` files from their templates, symlinks the config into place (existing files go to `~/.backups/dotfiles/<timestamp>/`), and switches the login shell to zsh (`--skip-shell` to opt out).

**Fedora:** install [Homebrew on Linux](https://docs.brew.sh/Homebrew-on-Linux) and [Ghostty](https://ghostty.org/docs/install/binary) first.

OS defaults: `./scripts/macos-defaults.sh` or `./scripts/linux-defaults.sh`.

## Layout

| Path                             | Contents                                                          |
| -------------------------------- | ----------------------------------------------------------------- |
| `shell/`                         | zsh config; `zshrc.local` is loaded last                          |
| `git/`                           | shared `config`; identity in `gitconfig.local`                    |
| `homebrew/`, `fedora/`           | Brewfile and native Fedora packages                               |
| `nvim/`                          | LazyVim config ([README](nvim/README.md))                         |
| `tmux/`, `starship/`, `ghostty/` | terminal config                                                   |
| `bin/`                           | `clip.sh`, `awsme-sso.sh` (must be sourced)                       |
| `aws/`, `kube/`                  | config templates                                                  |
| `ai/`                            | AI assistant config (see below)                                   |
| `scripts/`                       | install, OS defaults, `check.sh`                                  |

## AI assistants

`ai/AGENTS.md` is the global instructions file for Claude Code (`~/.claude/CLAUDE.md`) and Copilot CLI. `ai/skills/` is shared by both. Claude-only settings, subagents and hooks live in `ai/claude/`. The repo-root `AGENTS.md` only covers working on this repo.

## Checks

```bash
./scripts/check.sh
```

Lints, syntax-checks and bootstraps into a throwaway `$HOME`. CI runs it on macOS and Fedora.

See [CONTRIBUTING.md](CONTRIBUTING.md) for the rules.
