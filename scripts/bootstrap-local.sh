#!/usr/bin/env bash
set -euo pipefail

# Create local-only config files from tracked templates and run safety checks.
# Use templates when configs include PII

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -f "${ROOT_DIR}/git/gitconfig.local" ]]; then
  cp "${ROOT_DIR}/git/gitconfig.local.template" "${ROOT_DIR}/git/gitconfig.local"
  echo "Created git/gitconfig.local from template (set your [user] identity)"
elif grep -qE '^\[(alias|fetch)\]' "${ROOT_DIR}/git/gitconfig.local"; then
  # Older layouts copied the shared settings into the local file, where they shadow git/config.
  echo "WARN: git/gitconfig.local has [alias]/[fetch] sections that override git/config; keep only [user] and machine-specific settings" >&2
fi

if [[ ! -f "${ROOT_DIR}/aws/config.local" ]]; then
  cp "${ROOT_DIR}/aws/config.template" "${ROOT_DIR}/aws/config.local"
  echo "Created aws/config.local from template"
fi

if [[ ! -f "${ROOT_DIR}/kube/config.eks.local.yaml" ]]; then
  cp "${ROOT_DIR}/kube/config.eks.template.yaml" "${ROOT_DIR}/kube/config.eks.local.yaml"
  echo "Created kube/config.eks.local.yaml from template"
fi

echo "Local bootstrap complete."
