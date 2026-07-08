# Self-Hosted Remote State Demo

Deploys env0's official [`remote-state-bucket-module`](https://github.com/env0/remote-state-bucket-module) into your own AWS account, so env0 remote-backend state lives in an S3 bucket **you own** while env0 keeps operating the backend service (locking, versioning, the team-facing UX).

This is **not** a migration off the env0 backend — it's a migration of *where the bucket lives*. If you want to leave the env0 backend entirely and self-manage state + locking, see [`../state-migration-s3-dynamodb/`](../state-migration-s3-dynamodb/README.md) instead.

## What This Creates

- An S3 bucket in your AWS account (versioned, encrypted) via env0's module
- An IAM role with a trust policy scoped to env0's principal + your org ID — only env0, acting on behalf of *your* organization, can read or write the bucket
- No DynamoDB table — env0's backend handles locking internally in this path

## Why This Exists

Customers move state into their own bucket for three reasons: CSPM/vulnerability scanners (Wiz, Prisma) need it in-account to see it, data-residency/sovereignty mandates require customer data stay in a boundary you can attest to, and it shortens vendor-review conversations. If none of those apply, env0's hosted state is already SOC 2 Type II attested — this is a posture choice, not a security upgrade by default.

## env0 Setup

| Field | Value |
|---|---|
| **IaC Type** | Terraform |
| **Terraform Version** | >= 1.5 |
| **Working Directory** | `state-migration-self-hosted` |
| **Plan** | Requires env0 Enterprise (Cloud Pilot) — self-hosted remote state is gated to that tier |

**Important:** on the environment you create for this template, make sure **"Use env zero Remote Backend" is disabled**. This module is what creates your state bucket — if it tried to use the env0 remote backend you're replacing, that's a chicken-and-egg failure.

## Variables

| Name | Type | Description |
|---|---|---|
| `external_id` | string | Your env0 Organization ID (Organization Settings) |
| `state_bucket_name` | string | Globally unique S3 bucket name (default: `demo-env0-self-hosted-state`) |
| `aws_region` | string | AWS region (default: `us-east-1`) |

## Prerequisites

- env0 organization administrator with **Edit Organization Settings** permission
- env0 SaaS (not air-gapped/special-region), standard commercial AWS partition (not GovCloud)
- Deploying principal needs `iam:CreateRole`, `iam:PutRolePolicy`, `s3:CreateBucket`, `s3:PutBucketVersioning`, `s3:PutBucketEncryption`, `s3:PutBucketPolicy`, plus tagging permissions
- A maintenance window — once env0 support repoints your org, **every** env0 remote-backend environment in the org uses the new bucket. There's no per-environment toggle.
- Backups of every in-scope state file, pulled *before* cutover
- Optionally, `ENV0_API_KEY` and `ENV0_ORGANIZATION_ID` set on this environment to enable the pre-apply inventory hook (see below)

## What env0.yaml Does

- **Before apply:** runs `scripts/inventory-remote-backend-envs.sh` to count remote-backend environments per project (your migration scope and support's reconciliation checklist), then prints the pre-cutover checklist (backup, freeze, have inventory ready)
- **After apply:** prints the four module outputs formatted to copy straight into an email to `support@env0.com`

## Post-Deploy: Notify env0 Support

Email the four printed outputs to `support@env0.com`:

```
role_arn:    arn:aws:iam::<account>:role/env0-remote-state-bucket
external_id: <your env0 org ID>
region:      us-east-1
bucket_name: acme-env0-state-prod
```

Support will schedule a coordinated cutover: freeze in-scope environments, copy existing state into your bucket, flip the backend pointer, then you validate a pilot environment (expect a `terraform plan` with zero changes) before rolling through non-prod and production tiers.

## Outputs

| Name | Description |
|---|---|
| `role_arn` | IAM role ARN env0 assumes to access your bucket |
| `external_id` | Your env0 Organization ID, echoed back |
| `region` | AWS region of your bucket |
| `bucket_name` | Name of the created S3 bucket |

## Sources

- env0 docs — [Using Self-Hosted Remote State](https://docs.envzero.com/guides/admin-guide/remote-backend/self-hosted-remote-state)
- env0 docs — [Migrating State](https://docs.envzero.com/guides/admin-guide/remote-backend/state-migration)
- Module source: [`github.com/env0/remote-state-bucket-module`](https://github.com/env0/remote-state-bucket-module)
