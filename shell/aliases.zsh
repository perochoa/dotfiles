#!/bin/zsh

if (( $+commands[eza] )); then
  alias ls="eza"
  alias l="eza -alha --color=always --icons=always --classify --no-filesize --no-time --no-user --no-permissions --git --group-directories-first"
  alias ll="eza -alhamU --icons=always --classify --git --group-directories-first"
  alias tree="eza --tree"
else
  alias ls="ls --color=auto"
  alias l="ls -lAh"
  alias ll="ls -lAh"
fi
alias path='print -rl -- $path'
alias history='history 0'
alias cg='cd $(git rev-parse --show-toplevel)'
alias grep='grep --color=auto'

# AWS: per-profile sign-in aliases are machine-specific and live in shell/zshrc.local
alias aws-copy-creds='env | grep -i "AWS" | ${DOTFILES}/bin/clip.sh'

# Kubernetes
alias kl='kubectl'
alias kx='kubectx'
