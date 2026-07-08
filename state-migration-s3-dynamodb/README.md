# Standalone S3 + DynamoDB Backend Demo

Creates a standard Terraform S3 backend — state in your bucket, locking in your DynamoDB table (or S3-native locking) — for customers who want to leave the env0 remote backend **entirely**. env0 becomes just the runner; it's no longer the backend.

This is the "Appendix" path. If you want to keep env0's remote-backend features (locking, versioning, team UX) while moving the underlying bucket into your account, see [`../state-migration-self-hosted/`](../state-migration-self-hosted/README.md) instead — that's what most customers actually want when they ask for "state in my own S3 + DynamoDB."

## What This Creates

- S3 bucket for Terraform state (versioned, AES-256 encrypted, public access blocked)
- DynamoDB lock table with a single string partition key, `LockID` (toggle off with `use_dynamodb_locking = false` to use S3-native locking instead — Terraform/OpenTofu 1.10+ and AWS provider v5+ support `use_lockfile = true` and HashiCorp has deprecated the DynamoDB-based pattern)

## Why This Exists

Some customers want full ownership of both state *and* locking, with no env0 backend involved at all. That's a different ask from data-residency/scanning-driven requests, which are usually satisfied by self-hosted remote state instead — see the companion demo above for that distinction.

## env0 Setup

| Field | Value |
|---|---|
| **IaC Type** | Terraform |
| **Terraform Version** | >= 1.5 |
| **Working Directory** | `state-migration-s3-dynamodb` |

## Variables

| Name | Type | Description |
|---|---|---|
| `state_bucket_name` | string | Globally unique S3 bucket name (default: `demo-env0-tfstate`) |
| `use_dynamodb_locking` | bool | Create a DynamoDB lock table; set `false` for S3-native locking (default: `true`) |
| `dynamodb_table_name` | string | DynamoDB table name, only used when locking is enabled (default: `demo-env0-tfstate-lock`) |
| `aws_region` | string | AWS region (default: `us-east-1`) |

## Post-Deploy Output

`env0.yaml` prints the bucket/table details, a ready-to-paste `backend "s3" {}` block, and the per-environment migration sequence:

1. Add the printed backend block alongside the existing env0 remote backend so Terraform can see both
2. `terraform login backend.api.env0.com` (provide your env0 token)
3. `terraform plan` — confirm you're targeting the right environment
4. `terraform state pull > backup.state` (recommended)
5. Replace the env0 backend block with the `s3` backend block
6. `terraform init -migrate-state` (answer `yes`)
7. `terraform plan` — expect zero changes
8. Mark the env0 environment inactive once validated

## Outputs

| Name | Description |
|---|---|
| `bucket_name` | S3 bucket name |
| `dynamodb_table_name` | DynamoDB table name (`null` if using S3-native locking) |
| `aws_region` | Region where resources were created |
| `backend_config_snippet` | Rendered `terraform { backend "s3" {} }` block to paste into migrating environments |

## Permissions Needed by the Deploying Principal

The principal running `terraform apply` against this template (not the bucket's own policy) needs:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket",
        "s3:PutBucketVersioning",
        "s3:PutBucketEncryption",
        "s3:PutBucketPolicy",
        "s3:PutBucketPublicAccessBlock",
        "s3:PutBucketTagging"
      ],
      "Resource": "arn:aws:s3:::<your-state-bucket-name>"
    },
    {
      "Effect": "Allow",
      "Action": ["dynamodb:CreateTable", "dynamodb:DescribeTable", "dynamodb:TagResource"],
      "Resource": "arn:aws:dynamodb:*:*:table/<your-lock-table-name>"
    }
  ]
}
```

The Terraform principal that later *runs against* the migrated backend only needs `dynamodb:GetItem`, `PutItem`, `DeleteItem`, `DescribeTable` on the lock table.

## Resources Created

```
aws_s3_bucket
aws_s3_bucket_versioning
aws_s3_bucket_server_side_encryption_configuration
aws_s3_bucket_public_access_block
aws_dynamodb_table (optional)
```

## Sources

- env0 docs — [Migrating State](https://docs.envzero.com/guides/admin-guide/remote-backend/state-migration) ("Migrating from env zero remote backend to a third-party bucket")
- env0 docs — [Remote Backend overview](https://docs.envzero.com/guides/admin-guide/remote-backend)
