#!/bin/bash

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

log_info "Your AWS creds for ${txtblu}${AWS_ENV_NAME}${txtrst}:${txtblu}${AWS_ACCOUNT_ID}${txtrst} are valid until ${txtylw}$(date -v +12H)${txtrst}"
