# Agent Guidance

When modifying this dotfiles tree:

1. Treat `~/.config/dotfiles` as the only repository root.
2. Never commit secrets, session tokens, kube client keys, or auth caches.
3. Prefer template + local override pattern:
   - tracked: `*.template`, reusable scripts, stable settings
   - local-only: `*.local`, runtime state, machine-specific outputs
4. Keep shell behavior stable on this host while making repo-safe changes.
5. Update `README.md` when structure or bootstrap behavior changes.
