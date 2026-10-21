#!/bin/zsh

# Environment shared by macOS and Linux. Loaded first so later modules can rely on it.

# Homebrew: macOS (Apple Silicon / Intel) or Linuxbrew. Skipped if shellenv already ran (e.g. via ~/.zprofile).
# brew on PATH alone is not enough: terminal.zsh finds the zsh plugins through HOMEBREW_PREFIX.
if [[ -z ${HOMEBREW_PREFIX:-} ]]; then
  for _brew in $commands[brew] /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
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
[[ -f "${DOTFILES}/aws/config.local" ]] && export AWS_CONFIG_FILE="${DOTFILES}/aws/config.local"

_kubeconfigs=()
for _kc in "${DOTFILES}/kube/config.eks.local.yaml" "${HOME}/.kube/config.local"; do
  [[ -f $_kc ]] && _kubeconfigs+=("$_kc")
done
(( ${#_kubeconfigs} )) && export KUBECONFIG="${(j.:.)_kubeconfigs}"
unset _kc _kubeconfigs
