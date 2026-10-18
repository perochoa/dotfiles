#!/bin/bash

# Usage: source awsme-sso.sh <profile>   (the aliases in shell/aliases.zsh and `cs` do this)
# Must be sourced so the exported credentials reach the calling shell; running it directly does nothing useful.
if ! (return 0 2>/dev/null); then
  echo "awsme-sso must be sourced: source ${0} <profile>" >&2
  exit 1
fi

# log_info comes from shell/functions.zsh; fall back to plain output when sourced elsewhere.
type log_info >/dev/null 2>&1 || log_info() { printf '%b\n' "$1"; }

unset AWS_DEFAULT_PROFILE
unset AWS_ACCOUNT_ID
unset AWS_ACCESS_KEY_ID
unset AWS_SESSION_TOKEN
unset AWS_SECRET_ACCESS_KEY
unset AWS_EXPIRATION_TIME
unset AWS_ENV_NAME

AWS_ENV_NAME="${1}"

AWS_DEFAULT_PROFILE="${AWS_ENV_NAME}"
export AWS_DEFAULT_PROFILE

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

if ! aws sts get-caller-identity &>/dev/null; then
  aws sso login --profile "${AWS_DEFAULT_PROFILE}"
fi
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
AWS_CREDS=$(aws configure export-credentials --format env-no-export)

eval "$AWS_CREDS"

export AWS_ACCOUNT_ID
export AWS_ACCESS_KEY_ID
export AWS_SESSION_TOKEN
export AWS_SECRET_ACCESS_KEY
export AWS_EXPIRATION_TIME
export AWS_ENV_NAME

# BSD date (macOS) uses -v; GNU date (Linux) uses -d
AWS_VALID_UNTIL=$(date -v +12H 2>/dev/null || date -d '+12 hours')

log_info "Your AWS creds for ${txtblu}${AWS_ENV_NAME}${txtrst}:${txtblu}${AWS_ACCOUNT_ID}${txtrst} are valid until ${txtylw}${AWS_VALID_UNTIL}${txtrst}"
unset AWS_VALID_UNTIL
