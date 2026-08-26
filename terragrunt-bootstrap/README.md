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
| `bucket_name` | string | S3 bucket name for state storage. Default `""` auto-generates a unique name (`demo-env0-terragrunt-state-<8 hex chars>`) — S3 bucket names are unique account-wide, so repeat deploys of this demo in the same account will collide on a fixed name |
| `dynamodb_table_name` | string | DynamoDB table name for state locking. Default `""` auto-generates a matching unique name |
| `environment` | string | Environment name for tagging |

## Post-Deploy Output

After deployment, env0.yaml prints the backend configuration details:

```
S3 bucket:      demo-env0-terragrunt-state-a1b2c3d4
DynamoDB table: demo-env0-terragrunt-lock-a1b2c3d4
Region:         us-east-2
```

In the `terragrunt-workflow/` demo, wire these into the `terragrunt` stage as `TG_STATE_BUCKET` / `TG_STATE_DYNAMODB_TABLE` / `TG_STATE_REGION` Environment Variables sourced from this stage's outputs — see `terragrunt/README.md`. Outside a workflow, copy them by hand into `terragrunt.hcl`.

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
random_id (name suffix, only when bucket_name/dynamodb_table_name are left empty)
aws_s3_bucket
aws_s3_bucket_versioning
aws_s3_bucket_server_side_encryption_configuration
aws_s3_bucket_public_access_block
aws_dynamodb_table
```
