---
name: k8s-access
description: Run kubectl against AWS EKS clusters on this machine. Use when inspecting or debugging cluster workloads, picking a kube context or AWS profile, signing in to AWS for kubectl, or fixing kubectl auth errors (Unauthorized, expired token, missing context).
---

# Kubernetes (EKS) access

Clusters, contexts and AWS profiles are machine-specific and live in untracked files, so
**discover them; never guess**.

## How it fits together

| What                              | Where                                                                                                        |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| AWS profiles (SSO or `aws login`) | `$AWS_CONFIG_FILE` → `~/.config/dotfiles/aws/config.local`                                                   |
| Kube contexts                     | `$KUBECONFIG` → `~/.config/dotfiles/kube/config.eks.local.yaml` and `~/.kube/config.local` (whichever exist) |
| Sign-in helper                    | `~/.local/bin/awsme-sso` → `bin/awsme-sso.sh` (must be sourced)                                              |
| Profile aliases, `cs` helper      | `~/.config/dotfiles/shell/zshrc.local` (optional, interactive shells only)                                   |

Each context's user runs `aws eks get-token` through an exec plugin, usually with `AWS_PROFILE`
pinned in the kubeconfig. So kubectl only needs **a valid session for that profile**; it does not
need `awsme-sso` sourced in the same command.

Use `kubectl`, not the `kl`/`kx` aliases: tool shells are not interactive. `kubectl` is not in
`homebrew/Brewfile`; if `command -v kubectl` finds nothing, tell the user instead of installing it.

## 1. Discover

```bash
# context, cluster ARN (holds the region), namespace, pinned AWS_PROFILE; one per line
kubectl config view -o json | jq -r '
  (.users | map({(.name): .user}) | add) as $u
  | .contexts[] | [.name, .context.cluster, (.context.namespace // "-"),
      ($u[.context.user].exec.env // [] | map(select(.name=="AWS_PROFILE").value) | first // "-")]
  | @tsv'
kubectl config current-context
aws configure list-profiles
```

Pick the context from the task. Working-directory hints (`production`/`staging`/`development`,
`us-east-1`/`us-east-2`) only narrow the candidates; confirm against the list and ask when more
than one fits. Never assume a namespace: take it from the task, the context, or ask.

## 2. Check the session

```bash
aws sts get-caller-identity --profile <profile>
```

If it fails, sign-in needs a browser, which a tool call can't finish. Ask the user to run it
with the `!` prefix so it lands in the session:

- SSO profile: `! aws sso login --profile <profile>`
- `aws login` profile (has `login_session`, check with
  `aws configure get login_session --profile <profile>`): `! aws login --profile <profile>`

Don't retry sign-in in a loop.

## 3. Run

```bash
kubectl --context <context> -n <namespace> get pods
```

Always pass `--context` (and `-n`) explicitly, and say which context and namespace a command
targets. Never run `kubectx`, `kubens`, `kubectl config use-context` or `cs` unless asked: they
change the current context in the shared kubeconfig, which moves the user's other terminals too.

### Credentials gotcha

Sourcing `awsme-sso` for an SSO profile **exports static credentials**
(`AWS_ACCESS_KEY_ID`, …). The exec plugin inherits them and they beat the pinned `AWS_PROFILE`,
so kubectl authenticates as the wrong account. If the shell has them and the context's profile
differs, drop them for the call:

```bash
env -u AWS_ACCESS_KEY_ID -u AWS_SECRET_ACCESS_KEY -u AWS_SESSION_TOKEN \
  kubectl --context <context> -n <namespace> get pods
```

Source `awsme-sso` only for a context without a pinned profile, or when the same command also
runs other AWS CLI calls, and then in that same command:
`source ~/.local/bin/awsme-sso <profile> && kubectl --context <context> …`.

## Troubleshooting

| Symptom                                                             | Likely cause → fix                                                                                                                                                          |
| ------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Error loading SSO Token` / `Token has expired` / `get-token` fails | Session expired → step 2                                                                                                                                                    |
| `You must be logged in to the server (Unauthorized)`                | Wrong principal: compare `aws sts get-caller-identity` with the context's profile (see gotcha); otherwise the role has no EKS access entry. Tell the user, don't change IAM |
| `context "<x>" does not exist`                                      | Not in `$KUBECONFIG` → add it (below)                                                                                                                                       |
| `executable aws not found`                                          | `aws` missing from `PATH` in the tool shell                                                                                                                                 |
| `forbidden: User "…" cannot …`                                      | Authenticated but RBAC denies it. Report it, don't work around it                                                                                                           |

## Adding a cluster context

Ask first; this writes a local, untracked file:

```bash
aws eks update-kubeconfig --name <cluster> --region <region> --alias <context> \
  --profile <profile> --kubeconfig ~/.config/dotfiles/kube/config.eks.local.yaml
```

`--profile` pins `AWS_PROFILE` in the new user entry. `aws eks list-clusters --region <region>
--profile <profile>` finds cluster names.

## Safety

- Read-only commands (`get`, `describe`, `logs`, `top`, `events`, `auth can-i`) are fine once
  the target is confirmed.
- Ask before anything that mutates a cluster or reaches into it: `apply`, `create`, `delete`,
  `edit`, `patch`, `scale`, `rollout restart`, `drain`, `cordon`, `exec`, `cp`, `port-forward`.
  Production needs explicit confirmation every time.
- Don't print Secret contents (`get secret -o yaml`, `describe secret` is fine); ask first.
