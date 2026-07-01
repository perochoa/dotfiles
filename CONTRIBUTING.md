# Contributing

> [!IMPORTANT]
> **TL;DR:** Keep changes reproducible, avoid committing secrets or runtime state, and update docs whenever structure or bootstrap behavior changes.

## Rules

1. Treat `~/.config/dotfiles` as the repository root.
2. Track reusable config and templates; keep machine-local files in `*.local` or `private/`.
3. Never commit secrets, session tokens, cert/key material, or caches.
4. Run `./bootstrap.sh` after structural changes to confirm symlinks and local templates still work.
5. Keep README and AGENTS docs in sync with any behavior or layout changes.

## Commit conventions

- Use concise, imperative commit subjects.
- Prefer one logical change per commit.
- Mention affected surfaces (for example `shell`, `nvim`, `aws`, `kube`, `copilot`) in the body when helpful.

## Validation before commit

```bash
# Basic checks (replace with your preferred secret scanner)
# Recommend installing and running detect-secrets or git-secrets before committing
git grep -En "AKIA|ghp_|AWS_SECRET_ACCESS_KEY|aws_secret_access_key" || true
zsh -n shell/*.zsh shell/zshrc
bash -n bootstrap.sh scripts/*.sh
```
