# Dotfiles

Personal configuration for macOS and Fedora Linux, kept at `~/.config/dotfiles`. Reusable config and templates are tracked; secrets, runtime state and machine-specific settings stay in untracked `*.local` files.

## Quick start

```bash
git clone https://github.com/perochoa/dotfiles ~/.config/dotfiles
cd ~/.config/dotfiles
./scripts/install-apps.sh   # packages (preview with --dry-run)
./bootstrap.sh              # local files, symlinks, login shell (preview with --dry-run)
```

`bootstrap.sh` is safe to re-run. It:

1. Creates `git/gitconfig.local`, `aws/config.local`, `kube/config.eks.local.yaml`, `shell/zshrc.local` and `ai/corrections.local.md` from their templates if missing.
2. Symlinks `~/.zshrc`, `~/.gitconfig`, `~/.config/git/config`, `~/.tmux.conf`, `~/.config/starship.toml`, `~/.config/nvim`, `~/.config/ghostty/config`, `~/.aws/config` (→ `aws/config.local`), the AI assistant config from `ai/` (see below), and each `bin/*.sh` as `~/.local/bin/<name>`. Existing files are moved to `~/.backups/dotfiles/<timestamp>/`.
3. Switches the login shell to the system zsh if needed (Fedora defaults to bash). `--skip-shell` opts out. The change applies to new login sessions: log out and back in, or run `exec zsh` in open terminals. `~/.zshrc` is zsh-only and refuses to load in bash.

## Layout

| Path                             | Contents                                                                                                                                               |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `shell/`                         | zsh config. `zshrc` sets `$DOTFILES` and loads `env.zsh` → `aliases.zsh` → `functions.zsh` → `terminal.zsh` → optional `zshrc.local`                   |
| `git/`                           | `config` (shared settings) and `gitconfig.local.template` (identity)                                                                                   |
| `homebrew/Brewfile`              | Packages for both OSes; macOS-only casks and formulae sit inside `if OS.mac?` (`claude-code` is a cross-platform cask)                                 |
| `fedora/packages.txt`            | Native Fedora packages installed with `dnf`                                                                                                            |
| `nvim/`                          | LazyVim config (see [`nvim/README.md`](nvim/README.md))                                                                                                |
| `tmux/`, `starship/`, `ghostty/` | Terminal, prompt and multiplexer config                                                                                                                |
| `bin/`                           | `clip.sh` (cross-platform clipboard) and `awsme-sso.sh` (AWS sign-in for SSO and `aws login` profiles; must be sourced)                                |
| `aws/`, `kube/`                  | Config templates; `~/.aws/config` links to `aws/config.local` (the shell also sets `AWS_CONFIG_FILE`) and `KUBECONFIG` points at the local kube copies |
| `ai/`                            | Shared config for AI coding assistants (see [AI assistants](#ai-assistants))                                                                           |
| `scripts/`                       | `install-apps.sh`, `macos-defaults.sh`, `linux-defaults.sh`, `check.sh`                                                                                |

## Platforms

Everything detects the OS at runtime, so the same files serve both machines.

- **macOS:** `install-apps.sh` runs `brew bundle`. `./scripts/macos-defaults.sh` applies Finder, Dock, screenshot and key-repeat settings.
- **Fedora:**
  1. Install [Homebrew on Linux](https://docs.brew.sh/Homebrew-on-Linux). `shell/env.zsh` finds it in `/home/linuxbrew/.linuxbrew`.
  2. `install-apps.sh` installs `fedora/packages.txt` with `dnf`, then the Brewfile (minus the macOS-only block; the `claude-code` cask has Linux builds), then Hack Nerd Font and the Copilot CLI.
  3. Install Ghostty from a COPR (it isn't in the official repos; see <https://ghostty.org/docs/install/binary>), e.g. `sudo dnf copr enable scottames/ghostty && sudo dnf install ghostty`. Check that the COPR builds for your Fedora release first.
  4. `./scripts/linux-defaults.sh` applies the GNOME equivalents of the macOS defaults (key repeat, folders first).

## AI assistants

Every AI coding assistant reads the same instructions and skills from `ai/`, so they all behave the same:

| Source                                                     | Linked as                                                       | Used by                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| ---------------------------------------------------------- | --------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ai/AGENTS.md` (global instructions)                       | `~/.claude/CLAUDE.md`, `~/.copilot/copilot-instructions.md`     | Claude Code, Copilot CLI                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| `ai/skills/` (`SKILL.md` skills)                           | `~/.agents/skills`, and each skill as `~/.claude/skills/<name>` | Copilot CLI, Claude Code                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| `ai/claude/settings.json`                                  | `~/.claude/settings.json`                                       | Claude Code only (tool-specific settings)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| `ai/claude/agents/` (subagents)                            | each agent as `~/.claude/agents/<name>.md`                      | Claude Code only. `architecture-auditor`: read-only audit against stack best practices plus a KISS/YAGNI simplification roadmap with before/after code.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| `ai/claude/hooks/`                                         | `~/.claude/hooks`                                               | Claude Code only. `git-guard.py` enforces the git rules in `ai/AGENTS.md`: no changes to `main`, branch naming, no plain force-push, commit message format (needs `python3`). A repo can override the branch regex with `git config ai.branchPattern`. `correction-check.py` spots prompts that correct the assistant and feeds it the corrections log. |
| `ai/corrections.local.md` (from `corrections.template.md`) | read in place                                                   | Every assistant: machine-local log of behavioural corrections, so repeats get turned into rules or hooks (see "Learning from corrections" in `ai/AGENTS.md`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |

Skills and agents are linked one by one into `~/.claude/skills` and `~/.claude/agents` because Claude Code also installs its own there. To support another assistant, add a `link` for its instructions file and skills directory in `bootstrap.sh`; tool-specific settings go in `ai/<tool>/`. The repo-root `AGENTS.md` is guidance for working on this repo, not the global instructions. Project-specific assistant config stays in each project.

## Machine-specific settings

- **Shell:** `shell/zshrc.local` (from `zshrc.local.template`), loaded last. Define this machine's AWS profile aliases here (each one sources `awsme-sso` for the profile of the same name in `aws/config.local`), plus employer- or machine-specific helpers such as the commented-out `cs` context switcher.
- **Git:** `git/gitconfig.local` (linked as `~/.gitconfig`) holds your identity and overrides `git/config`. `git config --global` writes there, never to the tracked file.
- **AWS / Kubernetes:** `aws/config.local`, `kube/config.eks.local.yaml`, and optionally `~/.kube/config.local`.

## Packages

Add a package to the Brewfile only if most machines need it and it installs from a public tap. Leave out hardware-specific, MDM-managed, per-machine or experimental apps. Fedora-native system packages go in `fedora/packages.txt`.

## Checks

```bash
./scripts/check.sh
```

Runs shellcheck and ruff (each if installed), bash/zsh/Python syntax checks, then bootstraps into a throwaway `$HOME` and verifies links, local files created from templates, backups, idempotency, the Claude hooks (on macOS also under `/usr/bin/python3`), git config layering, and a clean zsh startup. CI runs it on macOS and in a Fedora 44 container.

## Secrets

Never commit secrets, tokens, keys or auth caches; keep them in `*.local` files or `private/`. Before publishing changes, scan with a tool such as `detect-secrets` or `git-secrets`. If a secret was ever committed, rotate it and rewrite history (`git filter-repo`).
