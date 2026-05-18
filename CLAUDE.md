# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A collection of standalone Infrastructure-as-Code demos for the **env0 platform**. Each top-level folder is an independent demo — it gets imported into env0 as a template and deployed from there. There is no build system, test runner, or package manager.

## Local Terraform Commands

Each demo is self-contained. Run these from within the demo's directory (or `terraform/environments/<env>` for the full-stack demo):

```bash
terraform init
terraform validate
terraform plan -var-file=terraform.auto.tfvars   # if a tfvars file exists
terraform apply -var-file=terraform.auto.tfvars
terraform destroy -var-file=terraform.auto.tfvars
```

For Terragrunt demos:
```bash
terragrunt init
terragrunt plan
terragrunt apply
```

## Key File Conventions

| File | Purpose |
|---|---|
| `env0.yaml` | Custom flow hooks — runs before/after `terraformApply`, `terraformDestroy`, etc. (version 2 format) |
| `env0.workflow.yaml` | Orchestrates multiple environments with dependency ordering and approval gates |
| `terraform.auto.tfvars` | Auto-loaded variable overrides per environment |

### `env0.yaml` Structure
```yaml
version: 2
deploy:
  steps:
    terraformApply:
      before: [...]
      after: [...]
destroy:
  steps:
    terraformDestroy:
      before: [...]
```

### `env0.workflow.yaml` Structure
```yaml
environments:
  <name>:
    templateName: "<env0 template name>"
    needs: [<dependency>]       # optional dependency ordering
    requiresApproval: true      # optional approval gate
settings:
  environmentRemovalStrategy: destroy
```

## Repository Structure

```
env0-demos/
├── terraform/                  # Full-stack root module (VPC + SG + IAM + EC2 + S3)
│   ├── modules/{vpc,security_groups,iam,ec2,s3}/
│   └── environments/{dev,staging,prod}/terraform.auto.tfvars
├── aws-core/                   # AWS demos grouped together
│   ├── ec2-ansible/            #   Terraform + Ansible (env0.yaml chains ansible-playbook after apply)
│   ├── ecs-fargate/            #   ECS Fargate + ALB + ECR
│   └── vpc-rds/                #   Two-tier VPC + private RDS
├── s3-bucket/                  # Standalone Terraform modules (beginner → intermediate)
├── ec2/
├── vpc/
├── security-group/
├── iam-role/
├── cloudformation/             # CloudFormation via env0
├── custom-flows/               # env0.yaml examples: TFLint, multi-tool scanning, approval gates
├── terragrunt/                 # Terragrunt root config
├── terragrunt-bootstrap/       # Creates S3 + DynamoDB state backend
├── multi-tier-workflow/        # env0.workflow.yaml: VPC → DB → SG → EC2
├── terragrunt-workflow/        # env0.workflow.yaml: bootstrap → deploy
└── eks-workflow/               # env0.workflow.yaml: infra → apps with approval gate
```

## Module Dependency Order (full-stack `terraform/`)

`VPC` and `S3` (no deps) → `Security Groups` (needs VPC) → `IAM` (needs S3) → `EC2` (needs all)

Environment CIDRs: dev `10.0.x`, staging `10.1.x`, prod `10.2.x`

## Adding a New Demo

1. Create a top-level folder in kebab-case
2. Add `README.md` explaining what it provisions and what env0 variables to configure
3. Add `env0.yaml` if the demo needs custom steps around terraform apply/destroy
4. If it's a workflow, add `env0.workflow.yaml` instead (no `env0.yaml` needed at the workflow level)
