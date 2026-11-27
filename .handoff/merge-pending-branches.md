# Handoff: merge the pending branches

Written 2026-11-26. Everything below is pushed. Delete this file before the branch it's on merges
(same as `chore: rm handoffs`).

## Why it matters

`~/.claude/CLAUDE.md` links to `ai/AGENTS.md` on whatever branch is checked out, so a rule only
applies while its branch is checked out. The corrections log marks several rules as codified, but
they only live on unmerged branches. Right now `feat/voice-guard-hook` is checked out, so the voice
rule is active, but "No AI attribution on remotes" and "Working on tickets" aren't.

## Branches (all based on current `main`)

| Branch | What's on it | State |
|---|---|---|
| `chore/claude-auto-mode-settings` | generic auto mode environment in `ai/claude/settings.json` | PR #20 open, mergeable |
| `dev` | ticket workflow (rules + `ticket` skill) and the no-ai-attribution rule, plus `chore: rm handoffs` | no PR |
| `feat/ticket-workflow` | same 2 commits as on `dev` | covered by `dev` |
| `docs/no-ai-attribution-on-remotes` | same rule as on `dev` | covered by `dev` |
| `feat/voice-guard-hook` | `voice-guard.py` (blocks gh text posts until the voice skill is loaded), the "Writing in my voice" rule, and the rule that it covers comments in committed files too | no PR |
| `docs/write-in-my-voice` | the original voice rule commit | covered by `feat/voice-guard-hook` |

Checked with `git merge-tree`: PR #20 merges cleanly with both `dev` and `feat/voice-guard-hook`.
`dev` and `feat/voice-guard-hook` conflict in `ai/AGENTS.md` (both add sections next to each
other). Keep both sections.

## To do

1. Merge PR #20.
2. PR `dev` -> `main` (ticket workflow + no ai attribution). Double check `ai/AGENTS.md` doesn't
   end up with two "No AI attribution" bullets under Git commits.
3. Rebase `feat/voice-guard-hook` on the new `main`, fix the `ai/AGENTS.md` conflict, delete this
   file, then PR it.
4. Delete the covered branches (local and remote): `feat/ticket-workflow`,
   `docs/no-ai-attribution-on-remotes`, `docs/write-in-my-voice`.
5. Update the statuses in `ai/corrections.local.md` once they're on `main`. Entries still
   pointing at a branch: no-ai-attribution (2026-11-18), voice rule (2026-11-22, 2026-11-26),
   voice-guard hook (2026-11-25). The 2026-11-26 tech-18 entry says "enforcement pending".

## Not in git on purpose

The repo is public, so these are ignored and stay on this machine. Copy them over yourself if you
want them on another device:

- `ai/skills/voice/` (voice skill and samples, the voice rule depends on it)
- `ai/corrections.local.md` (corrections log)
- the usual `*.local` files (`aws/config.local`, `git/gitconfig.local`, `shell/zshrc.local`,
  `kube/config.eks.local.yaml`)
