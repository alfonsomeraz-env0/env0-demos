# serverless-api

A cheap, realistic serverless application demo for env0. Provisions an HTTP API backed by AWS Lambda and DynamoDB — costs effectively $0 at demo scale (all within AWS free tier).

## What it builds

| Resource | Details |
|---|---|
| API Gateway HTTP API | `GET /items`, `GET /items/{id}`, `POST /items`, `DELETE /items/{id}` |
| Lambda function | Python 3.12, 128 MB, 10s timeout |
| DynamoDB table | PAY_PER_REQUEST billing, no provisioned capacity |
| IAM role | Least-privilege — DynamoDB + CloudWatch Logs only |

## env0 variables to configure

| Variable | Default | Notes |
|---|---|---|
| `aws_region` | `us-east-1` | AWS region |
| `project_name` | `env0-demo` | Prefix for all resource names |
| `environment` | `dev` | Stamped on every resource tag and stored in each item |
| `lambda_memory_mb` | `128` | Raise to 256–512 to demo a plan diff |
| `lambda_timeout_seconds` | `10` | |

## Good PR changes to demo the env0 bot

Each of these produces a clear, readable plan diff when posted as a PR comment:

- **Change Lambda memory**: edit `lambda_memory_mb` in `variables.tf` (default 128 → 256) — shows an in-place update
- **Add a new field**: edit `src/handler.py` to stamp a `priority` field on created items — shows `source_code_hash` change
- **Add a route**: add a `PATCH /items/{id}` route in `api_gateway.tf` — shows 1 resource added
- **Add a GSI**: add a global secondary index to `dynamodb.tf` — shows a table update with index details

## Usage

```bash
# Deploy
terraform init
terraform apply

# List items
curl $(terraform output -raw items_endpoint)

# Create an item
curl -X POST $(terraform output -raw items_endpoint) \
  -H "Content-Type: application/json" \
  -d '{"name": "hello env0", "status": "active"}'

# Delete an item
curl -X DELETE $(terraform output -raw api_url)/items/<id>

# Teardown
terraform destroy
```
