#!/bin/bash

# Usage: source awsme-sso.sh <profile>   (aliases or helpers like `cs` in shell/zshrc.local do this)
# Logs in if needed and points the calling shell at the profile. SSO profiles (aws sso login) also export their
# temporary credentials; login_session profiles (aws login) don't, because the CLI rotates those every 15 minutes.

# shellcheck disable=SC2154 # colour variables (txt*) come from shell/functions.zsh
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

# login_session profiles (aws login) vs SSO profiles (aws sso login)
_awsme_sso=true
aws configure get login_session --profile "$AWS_PROFILE" >/dev/null 2>&1 && _awsme_sso=false

# One STS call proves the session and yields the account; log in and retry only when it fails.
if ! AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text 2>/dev/null)"; then
  if [ "$_awsme_sso" = true ]; then
    aws sso login --profile "$AWS_PROFILE" || { unset _awsme_sso; return 1; }
  else
    aws login --profile "$AWS_PROFILE" || { unset _awsme_sso; return 1; }
  fi
  AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)" || { unset _awsme_sso; return 1; }
fi
export AWS_ACCOUNT_ID

if [ "$_awsme_sso" = true ]; then
  # Sets AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN and AWS_CREDENTIAL_EXPIRATION
  eval "$(aws configure export-credentials --format env)" || { unset _awsme_sso; return 1; }
  _validity="valid until ${txtylw}${AWS_CREDENTIAL_EXPIRATION:-unknown}${txtrst}"
else
  _validity="refreshed by the CLI until the login session ends"
fi

log_info "Your AWS creds for ${txtblu}${AWS_ENV_NAME}${txtrst}:${txtblu}${AWS_ACCOUNT_ID}${txtrst} are ${_validity}"
unset _validity _awsme_sso
