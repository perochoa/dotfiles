---
name: cicd-patterns
description: CI/CD guidance. Use for GitLab pipeline structure, job safety, validation stages, and deployment controls.
---

# CI/CD Patterns and Best Practices

## Pipeline Structure
- Define explicit `stages:` at the top of the pipeline file
- Use a standard stage order: validate → build → test → deploy
- Keep jobs focused — one responsibility per job
- Name jobs descriptively in lowercase with hyphens (e.g., `lint-python`, `deploy-staging`)

## Secrets and Credentials
- All sensitive values must come from masked CI/CD variables — never hardcode in pipeline files
- Reference secrets as variables (`$VARIABLE_NAME`), not inline values
- Use separate credentials for each environment (dev, staging, production)

## Deployment Safety
- Require manual approval for production deployments — never auto-deploy to prod
- Every deploy job should have a corresponding rollback strategy or job
- Track deployments with environment metadata (`environment: name:`)
- Use `needs:` or `dependencies:` to declare explicit job dependencies when order matters

## Validation
- Include a `validate` stage that runs linters, `shellcheck`, and syntax checks before build/test
- Validate configuration files and scripts early to catch errors before expensive jobs run

## Job Configuration
- Set explicit `timeout:` on long-running jobs
- Mark non-deploy jobs as `interruptible: true` so redundant pipeline runs can be cancelled
- Use YAML anchors or `extends:` to avoid duplicating common configuration

## Rules and Triggers
- Use `rules:` instead of `only:/except:` — they cannot be mixed in the same job
- Be explicit about which branches and events trigger each job
- Avoid running expensive jobs on every commit to feature branches when a lighter check will do

## Best Practices
- Never use `allow_failure: true` on deploy jobs
- Never skip the validate stage to save time — catch errors early
- Keep pipeline definitions DRY — extract shared config into templates or includes
- Pin versions for tools and images used in CI jobs