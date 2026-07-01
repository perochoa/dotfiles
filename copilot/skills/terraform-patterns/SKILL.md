---
name: terraform-patterns
description: Terraform guidance and standards. Use for module structure, state safety, naming, and validation practices.
---

# Terraform Patterns & Standards

## Style and Conventions
- Use `terraform fmt` compatible formatting
- Use snake_case for all resource names, variables, and outputs
- Use descriptive resource names that indicate purpose (e.g., `aws_s3_bucket.data_lake_raw`)
- Group related resources in purpose-named files (e.g., `networking.tf`, `iam.tf`, `storage.tf`)

## Structure
- Separate `variables.tf`, `outputs.tf`, `main.tf`, `providers.tf`, and `versions.tf`
- Use modules for reusable infrastructure components
- Keep modules focused on a single concern
- Use `locals` blocks to reduce repetition and improve readability

## Variables and Outputs
- Always provide `description` and `type` for variables
- Use `validation` blocks for input constraints
- Set sensible `default` values where appropriate
- Mark sensitive variables with `sensitive = true`
- Provide `description` for all outputs

## State and Security
- Use remote state backends (S3, GCS, Azure Blob) with state locking
- Never store secrets in Terraform state or variables files
- Use data sources to reference existing infrastructure rather than hardcoding IDs or ARNs
- Use `terraform plan` output to verify changes before applying
- Add `lifecycle { prevent_destroy = true }` to stateful resources (databases, storage with data)
- Mark sensitive outputs with `sensitive = true`

## Tagging and Naming
- Apply consistent tags to all resources (environment, team, project, managed-by)
- Use a naming convention that includes environment and purpose
- Use `default_tags` in the provider block for common tags

## Loops and Conditionals
- Prefer `for_each` over `count` for resources with meaningful identities — avoids index-based state churn on changes
- Use `count` only for simple on/off toggles (e.g., `count = var.enabled ? 1 : 0`)

## Environment Separation
- Do not mix workspace-based and directory-based environment separation in the same repo
- Be consistent — pick one strategy and document it

## Versioning
- Pin provider versions with `~>` constraints
- Pin module versions to specific tags or commits
- Use `required_version` to enforce a minimum Terraform version
- Run `terraform fmt -recursive` and `terraform validate` before committing
