#!/bin/zsh

alias ls="eza"
alias l="eza -alha --color=always --icons=always --classify --no-filesize --no-time --no-user --no-permissions --git --group-directories-first"
alias ll="eza -alhamU --icons=always --classify --git --group-directories-first"
alias tree="eza --tree"
alias path='echo -e ${PATH//:/\\n} | sort | uniq'
alias history='history 0'
alias cg='cd $(git rev-parse --show-toplevel)'
alias grep='grep --color=auto'

# AWS Alias
# alias dts='source ${HOME}/.config/dotfiles/bin/awsme-sso.sh dts'
# alias dtp='source ${HOME}/.config/dotfiles/bin/awsme-sso.sh dtp'
# alias dtd='source ${HOME}/.config/dotfiles/bin/awsme-sso.sh dtd'
# alias ais1='source ${HOME}/.config/dotfiles/bin/awsme-sso.sh ais1'
# alias aip1='source ${HOME}/.config/dotfiles/bin/awsme-sso.sh aip1'
# alias aid1='source ${HOME}/.config/dotfiles/bin/awsme-sso.sh aid1'
# alias ais2='source ${HOME}/.config/dotfiles/bin/awsme-sso.sh ais2'
# alias aip2='source ${HOME}/.config/dotfiles/bin/awsme-sso.sh aip2'
# alias aid2='source ${HOME}/.config/dotfiles/bin/awsme-sso.sh aid2'
# alias aws-copy-creds='env | grep -i "AWS" | pbcopy'

# Kubernetes Alias
alias kl='kubectl'
alias kx='kubectx'
