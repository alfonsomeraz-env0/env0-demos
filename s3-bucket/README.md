# S3 Bucket Demo

Demonstrates deploying an AWS S3 bucket with versioning using Terraform, managed through env0.

## What This Creates

- S3 bucket with a configurable name
- Versioning enabled on the bucket

## env0 Setup

| Field | Value |
|---|---|
| **IaC Type** | Terraform |
| **Terraform Version** | >= 1.0 |
| **Working Directory** | `s3-bucket` |

## Variables

| Name | Type | Default | Description |
|---|---|---|---|
| `aws_region` | string | `us-east-1` | AWS region |
| `bucket_name` | string | — | S3 bucket name (must be globally unique) |
| `environment` | string | `dev` | Environment name |

## Custom Flow

The `env0.yaml` adds a step after variable setup to print the env0 environment context:

```
ENV0_ENVIRONMENT_ID
ENV0_PROJECT_NAME
ENV0_DEPLOYMENT_LOG_ID
```

This is useful for understanding how env0 exposes deployment metadata to your IaC steps.

## How to Run

1. Create a new environment in env0 using this template
2. Set `bucket_name` to a globally unique value (e.g. `my-company-demo-12345`)
3. Deploy — the bucket will be created with versioning enabled

## Resources Created

```
aws_s3_bucket
aws_s3_bucket_versioning
```
