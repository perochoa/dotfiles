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
alias path='echo -e ${PATH//:/\\n} | sort | uniq'
alias history='history 0'
alias cg='cd $(git rev-parse --show-toplevel)'
alias grep='grep --color=auto'

# AWS: each alias sources awsme-sso for the profile of the same name
for _profile in dts dtp dtd ais1 aip1 aid1 ais2 aip2 aid2; do
  alias "$_profile=source \${HOME}/.config/dotfiles/bin/awsme-sso.sh $_profile"
done
unset _profile
alias aws-copy-creds='env | grep -i "AWS" | ${HOME}/.config/dotfiles/bin/clip.sh'

# Kubernetes Alias
alias kl='kubectl'
alias kx='kubectx'
