#!/bin/zsh

function weather() {
  local location
  location="${1:-Toronto,ON}"
  curl "v2.wttr.in/${location}"
}

# Context Switch
# cs() {
#   declare -A CONTEXT_TO_AWS_ALIAS=(
#     ["aid1"]="aid1"
#     ["ais1"]="ais1"
#     ["aip1"]="aip1"
#     ["aid2"]="aid2"
#     ["ais2"]="ais2"
#     ["aip2"]="aip2"
#     ["dtd"]="dtd"
#     ["dts"]="dts"
#     ["dtp"]="dtp"
#     ["msd1"]="msd1"
#     ["mss1"]="ais1"
#     ["msp1"]="aip1"
#     ["msd2"]="msd2"
#     ["mss2"]="ais2"
#     ["msp2"]="aip2"
#   )
#
#   declare -A CONTEXT_TO_PATH=(
#     ["aid1"]="us-east-1/development"
#     ["ais1"]="us-east-1/staging"
#     ["aip1"]="us-east-1/production"
#     ["aid2"]="us-east-2/development"
#     ["ais2"]="us-east-2/staging"
#     ["aip2"]="us-east-2/production"
#     ["dtd"]="us-east-1/development"
#     ["dts"]="us-east-1/staging"
#     ["dtp"]="us-east-1/production"
#     ["msd1"]="us-east-1/development"
#     ["mss1"]="us-east-1/staging"
#     ["msp1"]="us-east-1/production"
#     ["msd2"]="us-east-2/development"
#     ["mss2"]="us-east-2/staging"
#     ["msp2"]="us-east-2/production"
#   )
#
#   local target_context="$1"
#
#   if [[ ! -v "CONTEXT_TO_AWS_ALIAS[$target_context]" ]]; then
#     log_error "Context '$target_context' not found in mapping"
#     return 1
#   fi
#
#   local aws_profile="${CONTEXT_TO_AWS_ALIAS[$target_context]}"
#   local target_path="${CONTEXT_TO_PATH[$target_context]}"
#   local git_root=$(git rev-parse --show-toplevel 2>/dev/null)
#   local new_path="${git_root}/${target_path}"
#
#   if [[ -d $new_path ]]; then
#     log_info "Changing directory to: $new_path"
#     cd $new_path
#   else
#     log_warn "$new_path does not exist in this directory"
#   fi
#
#   log_info "Switching kubectl context to: $target_context"
#   if ! kubectx "$target_context" 2>/dev/null; then
#     log_error "Failed to switch kubectl context"
#     return 1
#   fi
#
#   log_info "Switching AWS profile to: $aws_profile"
#   source "${HOME}/.config/dotfiles/bin/awsme-sso.sh" "$aws_profile"
#   log_info "✓ Current kubectl context: $(kubectx -c)"
#   log_info "✓ Current AWS profile: ${AWS_ENV_NAME:-not set}"
#   [[ -n "$git_root" ]] && log_info "✓ Current directory: $PWD"
#   if [[ -f "./init.sh" ]]; then
#     log_info "Running terraform init.sh"
#     ./init.sh
#   fi
# }
