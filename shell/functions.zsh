#!/bin/zsh

# Colours (also used by bin/awsme-sso.sh)
txtcyn="\e[0;36m"
txtblu="\e[0;34m"
txtylw="\e[0;33m"
bldred="\e[1;31m"
bldgrn="\e[1;32m"
bldylw="\e[1;33m"
bldpur="\e[1;35m"
txtrst="\e[0m"

__date_prefix() {
  printf "%b" "${txtcyn}$(date '+%Y-%b-%d %H:%M:%S')${txtrst}"
}

log_info() {
  printf "%b\n" "$(__date_prefix)${bldgrn} [INFO] ${txtrst}${1}"
}

log_debug() {
  printf "%b\n" "$(__date_prefix)${bldpur} [DEBUG] ${txtrst}${1}"
}

log_warn() {
  printf "%b\n" "$(__date_prefix)${bldylw} [WARN] ${txtrst}${1}"
}

log_error() {
  printf "%b\n" "$(__date_prefix)${bldred} [ERROR] ${txtrst}${1}"
}

function weather() {
  local location
  location="${1:-Toronto,ON}"
  curl "v2.wttr.in/${location}"
}

# Context Switch
cs() {
  # Contexts whose AWS profile differs from the context name
  declare -A CONTEXT_TO_AWS_ALIAS=(
    ["mss1"]="ais1"
    ["msp1"]="aip1"
    ["mss2"]="ais2"
    ["msp2"]="aip2"
  )

  declare -A CONTEXT_TO_PATH=(
    ["aid1"]="us-east-1/development"
    ["ais1"]="us-east-1/staging"
    ["aip1"]="us-east-1/production"
    ["aid2"]="us-east-2/development"
    ["ais2"]="us-east-2/staging"
    ["aip2"]="us-east-2/production"
    ["dtd"]="us-east-1/development"
    ["dts"]="us-east-1/staging"
    ["dtp"]="us-east-1/production"
    ["msd1"]="us-east-1/development"
    ["mss1"]="us-east-1/staging"
    ["msp1"]="us-east-1/production"
    ["msd2"]="us-east-2/development"
    ["mss2"]="us-east-2/staging"
    ["msp2"]="us-east-2/production"
  )

  local target_context="$1"

  if [[ ! -v "CONTEXT_TO_PATH[$target_context]" ]]; then
    log_error "Context '$target_context' not found in mapping"
    return 1
  fi

  local aws_profile="${CONTEXT_TO_AWS_ALIAS[$target_context]:-$target_context}"
  local target_path="${CONTEXT_TO_PATH[$target_context]}"
  local git_root=$(git rev-parse --show-toplevel 2>/dev/null)
  local new_path="${git_root}/${target_path}"

  if [[ -d $new_path ]]; then
    log_info "Changing directory to: $new_path"
    cd $new_path
  else
    log_warn "$new_path does not exist in this directory"
  fi

  log_info "Switching kubectl context to: $target_context"
  if ! kubectx "$target_context" 2>/dev/null; then
    log_error "Failed to switch kubectl context"
    return 1
  fi

  log_info "Switching AWS profile to: $aws_profile"
  source "${HOME}/.config/dotfiles/bin/awsme-sso.sh" "$aws_profile"
  log_info "✓ Current kubectl context: $(kubectx -c)"
  log_info "✓ Current AWS profile: ${AWS_ENV_NAME:-not set}"
  [[ -n "$git_root" ]] && log_info "✓ Current directory: $PWD"
  if [[ -f "./init.sh" ]]; then
    log_info "Running terraform init.sh"
    ./init.sh
  fi
}
