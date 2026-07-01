---
name: k8s-access
description: Know how to access AWS EKS Kubernetes clusters across dev/staging/prod environments and us-east-1/us-east-2 regions. Use when running kubectl commands, switching contexts, or debugging workloads on the mlops or microservices clusters.
---

# K8s Cluster Access

## Shell Aliases (Always Use These)
- `kl` = `kubectl`
- `kx` = `kubectx`
- `kxu` = `kubectx ${AWS_ENV_NAME}-${AWS_REGION}` (auto-switch to context matching current AWS env)
- `ks <env>` = **combo command**: switches kubectl context + AWS credentials + `cd`s to matching terraform dir + runs `init.sh` if present

## AWS Credential Aliases
Run these first to authenticate before any kubectl commands.
Each alias sources `awsme-sso.sh` which sets AWS_ENV_NAME, AWS_REGION, credentials, and triggers SSO login if needed.

| Alias | AWS Profile | Account ID | Env | Region |
|---|---|---|---|---|
| `aid1` | `aid1` | 418295676836 | dev | us-east-1 |
| `aid2` | `aid2` | 418295676836 | dev | us-east-2 |
| `ais1` | `ais1` | 051826741793 | staging | us-east-1 |
| `ais2` | `ais2` | 051826741793 | staging | us-east-2 |
| `aip1` | `aip1` | 084828600553 | prod | us-east-1 |
| `aip2` | `aip2` | 084828600553 | prod | us-east-2 |

> Legacy/other-team aliases: `dtd` (dev), `dts` (staging), `dtp` (prod) — old DT account, avoid for mlops.

## Kubernetes Contexts

### MLOps Cluster (`cfx-ai-mlops`)
| Context | Env | Region | AWS Profile |
|---|---|---|---|
| `aid1` | dev | us-east-1 | `aid1` |
| *(no aid2 context yet)* | dev | us-east-2 | `aid2` |
| `ais1` | staging | us-east-1 | `ais1` |
| `ais2` | staging | us-east-2 | `ais2` |
| `aip1` | prod | us-east-1 | `aip1` |
| `aip2` | prod | us-east-2 | `aip2` |

### Microservices Cluster (`cfx-ai-mlops-microservices`)
| Context | Env | Region | AWS Profile |
|---|---|---|---|
| `mss1` | staging | us-east-1 | `ais1` |
| `mss2` | staging | us-east-2 | `ais2` |
| `msp1` | prod | us-east-1 | `aip1` |
| `msp2` | prod | us-east-2 | `aip2` |

> No dev microservices cluster. `docker-desktop` = local only.

### Setup New Cluster Context
```bash
# After authenticating, run:
mlops_setup_cluster
# This runs: aws eks update-kubeconfig --alias "${AWS_ENV_NAME}-${AWS_REGION}" --name "${MLOPS_CLUSTER}" --region "${AWS_REGION}"
```

## Other Useful Aliases
- `mlops_ecr_docker_login` — authenticate Docker to ECR
- `mlops_ecr_podman_login` — authenticate Podman to ECR
- `aws-copy-creds` — copy current AWS env vars to clipboard

## `ks` — Switch Everything at Once (Preferred)

`ks <context>` does all of the following in one command:
1. Switches kubectl context
2. Switches AWS credentials (via `awsme-sso.sh`)
3. `cd`s to the matching terraform directory (e.g., `us-east-1/staging`) relative to the git root
4. Runs `./init.sh` if present in the target directory

**Valid `ks` arguments and their mappings:**

| `ks` arg | Kube Context | AWS Profile | Directory |
|---|---|---|---|
| `aid1` | `aid1` | `aid1` | `us-east-1/development` |
| `aid2` | `aid2` | `aid2` | `us-east-2/development` |
| `ais1` | `ais1` | `ais1` | `us-east-1/staging` |
| `ais2` | `ais2` | `ais2` | `us-east-2/staging` |
| `aip1` | `aip1` | `aip1` | `us-east-1/production` |
| `aip2` | `aip2` | `aip2` | `us-east-2/production` |
| `mss1` | `mss1` | `ais1` | `us-east-1/staging` |
| `mss2` | `mss2` | `ais2` | `us-east-2/staging` |
| `msp1` | `msp1` | `aip1` | `us-east-1/production` |
| `msp2` | `msp2` | `aip2` | `us-east-2/production` |
| `dtd` | `dtd` | `dtd` | `us-east-1/development` |
| `dts` | `dts` | `dts` | `us-east-1/staging` |
| `dtp` | `dtp` | `dtp` | `us-east-1/production` |

> Note: Microservices contexts (`mss*`/`msp*`) reuse the same AWS profile as the mlops contexts (`ais*`/`aip*`).

## Standard Workflow

```bash
# Option 1: Use ks (preferred — does everything)
ks aip1

# Option 2: Manual steps
aip1          # authenticate AWS
kx aip1       # switch kube context

# Then run commands
kl get pods -n <namespace>
kl get deployments -n <namespace>
kl logs <pod> -n <namespace>
```

## Decision Logic

When asked to run a kubectl command:

1. **Infer environment** from CWD path (`prod`/`staging`/`dev`) or ask the user.
2. **Infer region** from CWD path (`us-east-1`/`us-east-2`) or ask the user.
3. **Ask cluster type** if not obvious: mlops or microservices?
4. Look up the correct cred alias + context from the tables above.
5. Run: cred alias → `kx <context>` → `kl <command> -n <namespace>`

## CWD Inference Rules
- Path contains `prod`/`production` → env = prod
- Path contains `stag`/`staging` → env = staging
- Path contains `dev`/`development` → env = dev
- Path contains `us-east-1` → region = us-east-1
- Path contains `us-east-2` → region = us-east-2

## Hard Rules
- Always use `kl` not `kubectl`
- Always use `kx` not `kubectx`
- **Never assume a namespace** — always ask or derive from context
