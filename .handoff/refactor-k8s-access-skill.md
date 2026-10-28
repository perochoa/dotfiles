# refactor/k8s-access-skill

## Goal
Overhaul `ai/skills/k8s-access/SKILL.md` so agents use EKS clusters correctly and safely.

## Status
- [x] rewrite skill: discover → check session → run, troubleshooting table, safety list
- [x] verify the context-listing jq filter against template and local kubeconfig
- [ ] open PR to main
- [ ] decide whether to add `kubernetes-cli` to `homebrew/Brewfile` (kubectl isn't installed here)

## Decisions
- kubectl auth goes through the kubeconfig exec plugin with a pinned `AWS_PROFILE`, so the skill
  checks the session with `aws sts get-caller-identity --profile` instead of sourcing awsme-sso
  in every command.
- Agents must not run `kubectx`/`kubens`/`cs`/`use-context`: they change the shared kubeconfig's
  current context for every terminal.
- Browser sign-in is handed to the user as `! aws sso login …` / `! aws login …`.

## Gotchas
- awsme-sso on an SSO profile exports static keys; the exec plugin inherits them and they
  override the pinned profile (wrong account → Unauthorized). Skill documents `env -u …`.
- Branched from main; `dev` holds unrelated unmerged commits (prune, stale refs) that don't touch
  this skill.

## Key files
- `ai/skills/k8s-access/SKILL.md`, `bin/awsme-sso.sh`, `shell/env.zsh`,
  `shell/zshrc.local.template`, `kube/config.eks.template.yaml`
