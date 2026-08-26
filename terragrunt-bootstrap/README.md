# Terragrunt Bootstrap Demo

Creates the S3 bucket and DynamoDB table required for Terragrunt remote state management. This is the prerequisite for any Terragrunt-based deployment that uses remote state locking.

## What This Creates

- S3 bucket for Terraform state files (versioned, encrypted, public access blocked)
- DynamoDB table for state locking (prevents concurrent deploys from corrupting state)

## Why This Exists

Terragrunt needs a remote backend before any module can run. This bootstrap module creates that backend safely, with all production-grade S3 protections applied.

## env0 Setup

| Field | Value |
|---|---|
| **IaC Type** | Terraform |
| **Terraform Version** | >= 1.0 |
| **Working Directory** | `terragrunt-bootstrap` |

## Variables

| Name | Type | Description |
|---|---|---|
| `aws_region` | string | AWS region (default: `us-east-2`) |
| `bucket_name` | string | S3 bucket name for state storage (globally unique) |
| `dynamodb_table_name` | string | DynamoDB table name for state locking |
| `environment` | string | Environment name for tagging |

## Post-Deploy Output

After deployment, env0.yaml prints the backend configuration details:

```
S3 bucket:      my-tfstate-bucket
DynamoDB table: my-tfstate-lock
Region:         us-east-2
```

Copy these values into your `terragrunt.hcl` remote state configuration.

## Outputs

| Name | Description |
|---|---|
| `bucket_name` | S3 bucket name |
| `dynamodb_table_name` | DynamoDB table name |
| `aws_region` | Region where resources were created |

## S3 Bucket Configuration

- **Versioning** enabled (recover from accidental state deletion)
- **AES-256 encryption** at rest
- **Public access blocking** — all four block settings enabled
- **Object lock** disabled (state files need to be overwritten)

## Run Order

This module **must deploy before** any Terragrunt module that references this backend. Use the `terragrunt-workflow/` demo to automate this ordering.

## Resources Created

```
aws_s3_bucket
aws_s3_bucket_versioning
aws_s3_bucket_server_side_encryption_configuration
aws_s3_bucket_public_access_block
aws_dynamodb_table
```
