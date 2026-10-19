---
name: k8s-access
description: Access AWS EKS Kubernetes clusters with this dotfiles setup (awsme-sso, kubeconfig from kube/config.eks.local.yaml, kl/kx aliases, optional cs helper). Use when running kubectl commands, switching kube contexts or AWS profiles, or debugging cluster workloads.
---

# Kubernetes (EKS) access

Clusters, contexts and AWS profiles are machine-specific and live in untracked files, so
**discover them; never guess**. Nothing here is hardcoded on purpose.

## Where the configuration lives

| What | Source |
| --- | --- |
| AWS profiles (SSO or `aws login`) | `$AWS_CONFIG_FILE` → `~/.config/dotfiles/aws/config.local` |
| Kube contexts | `$KUBECONFIG` → `kube/config.eks.local.yaml` and `~/.kube/config.local` (whichever exist) |
| Per-profile sign-in aliases, `cs` helper | `~/.config/dotfiles/shell/zshrc.local` (may define neither) |
| Shared aliases | `kl` = `kubectl`, `kx` = `kubectx` (`shell/aliases.zsh`) |

## Discover before acting

```bash
aws configure list-profiles                 # available AWS profiles
kubectl config get-contexts                 # contexts; the current one is starred
kubectl config view --minify -o jsonpath='{.users[0].user.exec.env}'   # AWS_PROFILE a context's token uses, if pinned
zsh -ic 'whence -f cs' 2>/dev/null          # the cs mapping, if this machine defines one
echo "$AWS_PROFILE"                         # profile active in this shell
```

## Signing in

`awsme-sso` must be **sourced** so it can export into the shell:

```bash
source ~/.local/bin/awsme-sso <profile>     # or the profile alias from zshrc.local
```

It runs `aws sso login` or `aws login` only when the session is invalid, sets `AWS_PROFILE`,
`AWS_ENV_NAME` and `AWS_ACCOUNT_ID`, and for SSO profiles exports temporary credentials.
Each tool call runs in a fresh shell, so sign in and run kubectl in the **same command**:

```bash
source ~/.local/bin/awsme-sso <profile> && kubectl --context <context> get pods -n <namespace>
```

If `zshrc.local` defines `cs <context>`, it switches context, signs in, and `cd`s to the matching
terraform directory of the current repo in one step; check its mapping with `whence -f cs` first.

## Adding a cluster context

```bash
aws eks update-kubeconfig --name <cluster> --region <region> --alias <context> \
  --kubeconfig ~/.config/dotfiles/kube/config.eks.local.yaml
```

This writes a local, untracked file. Ask before running it.

## Rules

- Pass `--context <name>` explicitly instead of relying on the current context, and say which
  context and namespace a command targets.
- Never assume a namespace; derive it from the task or ask.
- Infer environment and region from the working directory (`production`/`staging`/`development`,
  `us-east-1`/`us-east-2`) only to pick a candidate, then confirm it against the discovered
  contexts. Ask when more than one fits.
- Read-only commands (`get`, `describe`, `logs`, `top`) are fine after confirming the target.
  Ask before anything that mutates a cluster (`apply`, `delete`, `scale`, `rollout restart`,
  `exec`, `port-forward`), and treat production as needing explicit confirmation every time.
- If sign-in needs a browser (SSO device flow), tell the user rather than retrying in a loop.
