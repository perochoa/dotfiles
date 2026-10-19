#!/bin/zsh

# Colours and log_* helpers (also used by bin/awsme-sso.sh and shell/zshrc.local)
txtcyn="\e[0;36m"
txtblu="\e[0;34m"
txtylw="\e[0;33m"
bldred="\e[1;31m"
bldgrn="\e[1;32m"
bldylw="\e[1;33m"
txtrst="\e[0m"

__date_prefix() {
  printf "%b" "${txtcyn}$(date '+%Y-%b-%d %H:%M:%S')${txtrst}"
}

log_info() {
  printf "%b\n" "$(__date_prefix)${bldgrn} [INFO] ${txtrst}${1}"
}

log_warn() {
  printf "%b\n" "$(__date_prefix)${bldylw} [WARN] ${txtrst}${1}"
}

log_error() {
  printf "%b\n" "$(__date_prefix)${bldred} [ERROR] ${txtrst}${1}"
}

weather() {
  curl "v2.wttr.in/${1:-Toronto,ON}"
}
