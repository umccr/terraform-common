# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

A library of reusable Terraform modules shared across UMCCR AWS infrastructure. Modules are consumed
by reference from other Terraform/Terragrunt stacks — this repo contains no root modules, backends, or state.

## Common commands

```bash
# Validate a module
terraform -chdir=modules/<module-name> init -backend=false
terraform -chdir=modules/<module-name> validate

# Format check
terraform fmt -recursive -check

# Format in place
terraform fmt -recursive
```

## Module conventions

- Each module lives under `modules/<name>/` with the standard files: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, and a `README.md`.
- `main.tf` holds data sources and locals only — no resources.
- `versions.tf` pins `required_version` and `required_providers` to the minimum versions that introduced features actually used in the module (not arbitrary recent versions).
- Modules must not declare a `provider` block; the caller provides the provider.
- Resource names are prefixed with `var.name_prefix` to allow multiple instantiations in the same account without conflicts.

## aws-seqera-iam-setup module

Creates the IAM principal (user + group + policy) and Secrets Manager secret that Seqera workspaces use to manage AWS Batch compute environments. Intended to be applied once per AWS account by a PlatformOwner, since IAM principal creation is restricted in the UMCCR organisation.

Key design points:
- The IAM policy scope is controlled by `var.tower_forge_prefix` (Seqera's `TowerForge-` prefix), which must match the value configured in Seqera Enterprise.
- The Secrets Manager secret is locked down via a resource policy that denies `GetSecretValue` / `PutSecretValue` to everyone except principals matching `var.admin_principal_arns` (defaults to the AWSAdministratorAccess and PlatformOwnerAccess SSO roles in the current account).
- Optional permissions (FSx Lustre, EFS) are off by default and enabled via `var.enable_fsx_lustre` / `var.enable_efs`. These are spliced into the IAM policy using `concat()` with a conditional list.
- `secret_string_wo` is used for the secret value (write-only, never stored in state), which requires AWS provider `~= 6.0` and Terraform `>= 1.11`.
