# EC2 Instance Demo

Demonstrates deploying an EC2 instance with security best practices using Terraform, managed through env0.

## What This Creates

- EC2 instance running Amazon Linux 2023 (latest AMI, auto-resolved)
- Encrypted gp3 root EBS volume
- IMDSv2 enforced (tokens required — no SSRF via metadata service)
- CloudWatch detailed monitoring enabled

## env0 Setup

| Field | Value |
|---|---|
| **IaC Type** | Terraform |
| **Terraform Version** | >= 1.0 |
| **Working Directory** | `ec2` |

## Variables

| Name | Type | Default | Required | Description |
|---|---|---|---|---|
| `aws_region` | string | `us-east-1` | No | AWS region |
| `environment` | string | `dev` | No | Environment name |
| `instance_name` | string | `demo-instance` | No | Name tag for the instance |
| `instance_type` | string | `t3.micro` | No | EC2 instance type |
| `subnet_id` | string | — | **Yes** | Subnet ID to launch into |
| `security_group_ids` | string (JSON-encoded list) | `""` | No | Security group IDs to attach, e.g. `["sg-0123"]`. Empty uses the VPC's default security group. |
| `root_volume_size` | number | `20` | No | Root volume size in GB |

> **Note:** `subnet_id` is required. Use the `vpc` demo to create a subnet first, or provide an existing one.

## How to Run

1. Create a new environment in env0 using this template
2. Set `subnet_id` to a valid subnet in your AWS account
3. Optionally add security group IDs for SSH/HTTP access
4. Deploy

## Security Features

- **IMDSv2 only** — prevents SSRF attacks targeting the instance metadata service
- **Encrypted EBS** — root volume encryption at rest
- **AMI auto-resolution** — always deploys the latest Amazon Linux 2023 AMI

## Resources Created

```
aws_instance (with root_block_device)
```
