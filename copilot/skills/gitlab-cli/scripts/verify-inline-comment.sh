#!/usr/bin/env bash
# verify-inline-comment.sh — Verify a GitLab discussion API response is an inline DiffNote
#
# Usage:
#   echo '<json_response>' | ./verify-inline-comment.sh
#   cat response.json | ./verify-inline-comment.sh
#
# Reads a GitLab discussion JSON response from stdin and checks that the first
# note has type "DiffNote" with a valid position. Exits 0 on success, 1 on failure.
#
# Requires: jq
set -euo pipefail

if [[ -t 0 ]]; then
  echo "Usage: echo '<discussion_json>' | $0" >&2
  echo "" >&2
  echo "Reads a GitLab discussion API response from stdin and verifies" >&2
  echo "the comment was placed as an inline DiffNote." >&2
  exit 1
fi

input=$(cat)

if ! echo "$input" | jq empty 2>/dev/null; then
  echo "ERROR: Invalid JSON input" >&2
  exit 1
fi

note_type=$(echo "$input" | jq -r '.notes[0].type // "unknown"')
position=$(echo "$input" | jq -r '.notes[0].position // empty')

if [[ "$note_type" != "DiffNote" ]]; then
  echo "FAIL: Comment was NOT placed inline — got type '${note_type}' instead of 'DiffNote'" >&2
  exit 1
fi

if [[ -z "$position" ]]; then
  echo "FAIL: Comment has no diff position!" >&2
  exit 1
fi

file_path=$(echo "$input" | jq -r '.notes[0].position.new_path // "unknown"')
line=$(echo "$input" | jq -r '.notes[0].position.new_line // .notes[0].position.old_line // "?"')
echo "OK: Inline DiffNote on ${file_path}:${line}"
