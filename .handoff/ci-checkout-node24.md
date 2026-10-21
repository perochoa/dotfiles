# ci/checkout-node24

## Goal
Clear the GitHub Actions notice "Node.js 20 is deprecated ... actions/checkout@v4" (seen on the fedora job).

## Status
- [x] `actions/checkout@v4` -> `@v7` (runs on node24) in both ci.yml jobs
- [x] `./scripts/check.sh` passes; pushed
- [ ] open a PR when the user asks; confirm the notice is gone on its CI run

## Decisions
- v7 over v5: latest major; changes since v4 (node24, creds in a separate file, fork-PR block for
  `pull_request_target`/`workflow_run`, ESM) don't affect this workflow's push/pull_request triggers.

## Key files
- `.github/workflows/ci.yml`
