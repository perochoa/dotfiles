#!/bin/bash

# Usage: source awsme-sso.sh <profile>   (the aliases in shell/zshrc.local and `cs` do this)
# Logs in if needed and points the calling shell at the profile. SSO profiles (aws sso login) also export their
# temporary credentials; login_session profiles (aws login) don't, because the CLI rotates those every 15 minutes.
if ! (return 0 2>/dev/null); then
  echo "awsme-sso must be sourced: source ${0} <profile>" >&2
  exit 1
fi

# log_info comes from shell/functions.zsh; fall back to plain output when sourced elsewhere.
type log_info >/dev/null 2>&1 || log_info() { printf '%b\n' "$1"; }

unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_CREDENTIAL_EXPIRATION AWS_ACCOUNT_ID
export AWS_ENV_NAME="$1"
export AWS_PROFILE="$1"
export AWS_DEFAULT_PROFILE="$1"

if aws configure get login_session --profile "$AWS_PROFILE" >/dev/null 2>&1; then
  if ! aws sts get-caller-identity >/dev/null 2>&1; then
    aws login --profile "$AWS_PROFILE" || return 1
  fi
  _validity="refreshed by the CLI until the login session ends"
else
  if ! aws sts get-caller-identity >/dev/null 2>&1; then
    aws sso login --profile "$AWS_PROFILE" || return 1
  fi
  # Sets AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN and AWS_CREDENTIAL_EXPIRATION
  eval "$(aws configure export-credentials --format env)" || return 1
  _validity="valid until ${txtylw}${AWS_CREDENTIAL_EXPIRATION:-unknown}${txtrst}"
fi

AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
export AWS_ACCOUNT_ID

# shellcheck disable=SC2154 # colour variables come from shell/functions.zsh
log_info "Your AWS creds for ${txtblu}${AWS_ENV_NAME}${txtrst}:${txtblu}${AWS_ACCOUNT_ID}${txtrst} are ${_validity}"
unset _validity
