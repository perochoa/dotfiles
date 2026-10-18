#!/bin/zsh

# Environment shared by macOS and Linux. Loaded first so later modules can rely on it.

dotfiles_dir="${HOME}/.config/dotfiles"

# Homebrew: macOS (Apple Silicon / Intel) or Linuxbrew. Skipped if already on PATH (e.g. via ~/.zprofile).
if (( ! $+commands[brew] )); then
  for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
    if [[ -x $_brew ]]; then
      eval "$($_brew shellenv)"
      break
    fi
  done
  unset _brew
fi

# PATH: ~/.local/bin holds the bin/ scripts linked by bootstrap.sh. -U drops duplicates.
typeset -U path
path=("$HOME/.local/bin" $path)

# Editor
if (( $+commands[nvim] )); then
  export EDITOR="nvim"
  export VISUAL="nvim"
fi

# History (Fedora's /etc/zshrc sets none of these, so history would not be saved)
HISTFILE="${HOME}/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt extended_history
setopt hist_ignore_dups
setopt hist_ignore_space
setopt share_history

# AWS / Kubernetes: point at the local files created from tracked templates
[[ -f "${dotfiles_dir}/aws/config.local" ]] && export AWS_CONFIG_FILE="${dotfiles_dir}/aws/config.local"

_kubeconfigs=()
for _kc in "${dotfiles_dir}/kube/config.eks.local.yaml" "${HOME}/.kube/config.local"; do
  [[ -f $_kc ]] && _kubeconfigs+=("$_kc")
done
(( ${#_kubeconfigs} )) && export KUBECONFIG="${(j.:.)_kubeconfigs}"
unset _kc _kubeconfigs
