# env0 Demos

A collection of Infrastructure-as-Code demos for the **env0 platform**, covering Terraform, Terragrunt, CloudFormation, Ansible, and env0 Workflows across a range of real-world patterns.

Each folder is a standalone demo — import it into env0 as a template and deploy.

---

## Demo Index

### AWS Core

| Demo | Description |
|---|---|
| [`aws-core/`](./aws-core/README.md) | Grouped collection of core AWS demos |
| [`aws-core/ec2-ansible/`](./aws-core/ec2-ansible/README.md) | Terraform + Ansible — provision EC2 and configure it in one env0 deploy |
| [`aws-core/ecs-fargate/`](./aws-core/ecs-fargate/README.md) | Serverless containers with ECS Fargate, ALB, and ECR |
| [`aws-core/vpc-rds/`](./aws-core/vpc-rds/README.md) | Two-tier VPC with private RDS instance |

### Serverless Application

| Demo | Description |
|---|---|
| [`serverless-api/`](./serverless-api/README.md) | HTTP API (API Gateway + Lambda + DynamoDB) — realistic app, near-zero cost, great for PR bot demos |

### Terraform Modules

| Demo | Description |
|---|---|
| [`s3-bucket/`](./s3-bucket/README.md) | S3 bucket with versioning — beginner-friendly starting point |
| [`ec2/`](./ec2/README.md) | EC2 instance (AL2023, IMDSv2, encrypted EBS) |
| [`vpc/`](./vpc/README.md) | VPC with public subnet, IGW, and route table |
| [`security-group/`](./security-group/README.md) | Security group with fully configurable dynamic ingress rules |
| [`iam-role/`](./iam-role/README.md) | IAM role with optional instance profile and inline policy |
| [`terraform/`](./terraform/README.md) | Full-stack root module composing VPC + SG + IAM + EC2 + S3 |

### Advanced Patterns

| Demo | Description |
|---|---|
| [`custom-flows/`](./custom-flows/README.md) | Custom flow examples: TFLint, multi-tool scanning, approval gates |
| [`pr-label-approval-policy/`](./pr-label-approval-policy/README.md) | Custom flow + OPA approval policy — auto-approve CI deploys, hold on PR label or deletions |
| [`cloudformation/`](./cloudformation/README.md) | CloudFormation via env0 — shows IaC-tool agnosticism |

### Terragrunt

| Demo | Description |
|---|---|
| [`terragrunt/`](./terragrunt/README.md) | Terragrunt root config — generates provider and version files dynamically |
| [`terragrunt-bootstrap/`](./terragrunt-bootstrap/README.md) | Creates the S3 + DynamoDB remote state backend for Terragrunt |

### env0 Workflows

| Demo | Description |
|---|---|
| [`multi-tier-workflow/`](./multi-tier-workflow/README.md) | Four-stage full-stack workflow: VPC → SG → S3 → EC2 with dependency ordering |
| [`terragrunt-workflow/`](./terragrunt-workflow/README.md) | Two-stage workflow: bootstrap state backend, then deploy Terragrunt stack |
| [`eks-workflow/`](./eks-workflow/README.md) | Multi-stage EKS workflow: infrastructure then applications, with approval gate |

### Coming Soon

| Demo | Description |
|---|---|
| [`mcp/`](./mcp/README.md) | MCP server integration — trigger env0 deployments from AI assistants |

---

## Quick Start

1. Fork or clone this repo
2. In env0, go to **Templates → Add Template**
3. Connect this repository and set the working directory to any demo folder
4. Configure variables as described in the folder's README
5. Deploy

---

## What Each Demo Covers

```
Beginner      s3-bucket → vpc → ec2
Intermediate  security-group → iam-role → terraform (full stack)
Serverless    serverless-api (API Gateway + Lambda + DynamoDB)
AWS Core      aws-core/ec2-ansible → aws-core/ecs-fargate → aws-core/vpc-rds
Advanced      custom-flows → cloudformation
Workflows     multi-tier-workflow → terragrunt-workflow → eks-workflow
```

---

## AWS Resources Used

All demos target AWS. You'll need:
- AWS credentials configured in env0 (IAM user or OIDC role)
- Sufficient permissions for the resources each demo creates (EC2, ECS, RDS, S3, VPC, IAM, Lambda, API Gateway, DynamoDB, CloudFormation)

---

## Repository Layout

```
env0-demos/
├── aws-core/                   # AWS Core demos
│   ├── ec2-ansible/            #   Terraform + Ansible
│   ├── ecs-fargate/            #   ECS Fargate + ALB + ECR
│   └── vpc-rds/                #   VPC + private RDS
├── serverless-api/             # Serverless — API Gateway + Lambda + DynamoDB
├── s3-bucket/                  # Terraform — S3 bucket
├── ec2/                        # Terraform — EC2 instance
├── vpc/                        # Terraform — VPC + networking
├── security-group/             # Terraform — Security group
├── iam-role/                   # Terraform — IAM role
├── terraform/                  # Terraform — Full stack (modules)
│   └── modules/
│       ├── vpc/
│       ├── security_groups/
│       ├── iam/
│       ├── ec2/
│       └── s3/
├── custom-flows/               # Custom flow examples
├── pr-label-approval-policy/   # Custom flow + OPA approval policy (PR labels)
├── cloudformation/             # CloudFormation
├── terragrunt/                 # Terragrunt config
├── terragrunt-bootstrap/       # Terragrunt state backend
├── multi-tier-workflow/        # env0 Workflow — full stack
├── terragrunt-workflow/        # env0 Workflow — Terragrunt
├── eks-workflow/               # env0 Workflow — EKS
└── mcp/                        # Coming soon
```

---

## Documentation

- [env0 Docs](https://docs.env0.com)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terragrunt Docs](https://terragrunt.gruntwork.io/docs)
