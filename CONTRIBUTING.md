# Contributing

- Keep every change working on both macOS and Fedora.
- Track reusable config and templates; machine-local files go in `*.local` or `private/`.
- Never commit secrets, tokens, keys or caches.
- Update the README when layout or bootstrap behaviour changes.
- Branches and commits follow the Git sections of [`ai/AGENTS.md`](ai/AGENTS.md) (`git-guard.py` enforces most of it).

Before committing:

```bash
./scripts/check.sh
git grep -En "AKIA|ghp_|AWS_SECRET_ACCESS_KEY|aws_secret_access_key"   # should print nothing
```
