# Contributing

## Rules

1. Treat `~/.config/dotfiles` as the repository root.
2. Track reusable config and templates; keep machine-local files in `*.local` or `private/`.
3. Never commit secrets, session tokens, cert/key material, or caches.
4. Keep every change working on both macOS and Fedora.
5. Update the README when layout or bootstrap behaviour changes.

## Commit conventions

Branches, commit messages and pull requests follow the Git sections of [`ai/AGENTS.md`](ai/AGENTS.md):
`<type>/<description>` branches, one logical change per commit, all-lowercase messages prefixed with
`<branch>: `, and changes reach `main` only through a pull request (`git-guard.py` enforces most of it).

In this repo, also mention the affected surfaces (for example `shell`, `nvim`, `aws`, `kube`, `ai`) in
the body when helpful.

## Validation before commit

```bash
# Lint, syntax-check, and smoke-test bootstrap in a throwaway $HOME (same as CI)
./scripts/check.sh

# Basic secret check (replace with your preferred scanner, e.g. detect-secrets or git-secrets)
git grep -En "AKIA|ghp_|AWS_SECRET_ACCESS_KEY|aws_secret_access_key" || true
```
