# Terragrunt Demo

Demonstrates using Terragrunt with env0 for DRY infrastructure configuration. `terragrunt.hcl` dynamically generates the provider, version, and S3 remote-state config, eliminating boilerplate.

`s3`, `vpc`, `iam`, `security_groups`, and `ec2` are plain Terraform modules called from the root `main.tf` (`module "vpc" { source = "./vpc" ... }`), wired together with normal `module.x.output` references — one Terraform stack, one plan, one apply. They are **not** separate Terragrunt units with their own `dependency` blocks: env0 always plans a whole Terragrunt run before applying any of it, so units that read a not-yet-applied sibling's output via `mock_outputs` (needed for `plan` to succeed pre-apply) get that mocked value baked into their saved plan file and never re-resolve it at apply time. On a cold deploy this makes a multi-unit stack fail predictably, one dependency tier per deploy attempt, until every tier has state from a prior run. Collapsing to one stack sidesteps it entirely — Terraform's own dependency graph orders resource creation correctly within a single apply, so this deploys cleanly on the first run.

## What This Shows

- Root `terragrunt.hcl` that generates `provider.tf`, `versions.tf`, and the S3 backend config at runtime
- Default AWS tags applied across all resources (`Environment`, `Project`, `ManagedBy`)
- How env0 handles Terragrunt as the IaC type
- Local Terraform modules composed in one stack instead of per-module Terragrunt units, to guarantee a correct first-run deploy

## env0 Setup

| Field | Value |
|---|---|
| **IaC Type** | Terragrunt |
| **Terraform Version** | >= 1.0 |
| **Terragrunt Version** | >= 0.50 |
| **Working Directory** | `terragrunt` |

## What `terragrunt.hcl` Generates

**`provider.tf`**
```hcl
provider "aws" {
  region = "us-east-2"
  default_tags {
    tags = {
      Environment = "dev"
      Project     = "demo-env0"
      ManagedBy   = "Terragrunt"
    }
  }
}
```

**`versions.tf`**
```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

These files are generated into the module directory at `terragrunt init` time and do not need to be committed.

## How to Run

1. Create a new environment in env0 with **IaC Type: Terragrunt**
2. Set the working directory to `terragrunt`
3. Deploy — Terragrunt generates the provider config and initializes modules

## Related Demos

- **`terragrunt-bootstrap/`** — creates the S3 + DynamoDB backend that Terragrunt uses for remote state
- **`terragrunt-workflow/`** — orchestrates bootstrap + deployment in a two-stage env0 workflow
