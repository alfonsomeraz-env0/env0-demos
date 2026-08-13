# SageMaker Notebook Demo (OpenTofu)

Provisions an Amazon SageMaker notebook instance with **OpenTofu**, managed through env0. Shows that env0 runs OpenTofu with the same templates, custom flows, and state handling as Terraform.

## What This Creates

- SageMaker notebook instance (`ml.t3.medium`, Amazon Linux 2023 platform)
- Execution role with a scoped inline policy (logs, self-stop, optional S3 buckets, KMS)
- Customer-managed KMS key + alias encrypting the ML storage volume
- Lifecycle configuration that stops the notebook once its kernels go idle
- IMDSv2-only metadata access, root access disabled for notebook users

## env0 Setup

| Field | Value |
|---|---|
| **IaC Type** | OpenTofu |
| **OpenTofu Version** | >= 1.6.0 |
| **AWS Provider** | >= 6.19.0 |
| **Working Directory** | `sagemaker` |

> **Provider floor matters here.** `notebook-al2023-v1` was only added to the AWS provider's `platform_identifier` validation in **6.19.0**; the 5.x line rejects it before the API is ever called. If you must stay on an older provider, set `platform_identifier = "notebook-al2-v3"`.

Custom flow format is identical between Terraform and OpenTofu, so `env0.yaml` still uses the `terraformInit` / `terraformApply` / `terraformDestroy` step names. The hooks resolve `tofu` or `terraform` at runtime, so the same file works under either IaC type.

## Variables

| Name | Type | Default | Required | Description |
|---|---|---|---|---|
| `aws_region` | string | `us-east-1` | No | AWS region |
| `environment` | string | `dev` | No | Environment name — prefixes every resource name |
| `notebook_name` | string | `demo-notebook` | No | Notebook name (suffix after the environment prefix) |
| `instance_type` | string | `ml.t3.medium` | No | ML compute instance type |
| `volume_size` | number | `5` | No | ML storage volume size in GB (5–16384) |
| `platform_identifier` | string | `notebook-al2023-v1` | No | Notebook runtime platform (needs AWS provider >= 6.19.0) |
| `root_access` | string | `Disabled` | No | Root access for notebook users |
| `direct_internet_access` | string | `Enabled` | No | SageMaker-provided internet access |
| `subnet_id` | string | `""` | No | Attach to your own VPC instead of the SageMaker-managed network |
| `security_group_ids` | list(string) | `[]` | No | Required when `subnet_id` is set (max 5) |
| `create_kms_key` | bool | `true` | No | Create a customer-managed key for the volume |
| `kms_key_arn` | string | `""` | No | Existing key ARN — used only when `create_kms_key = false` |
| `default_code_repository` | string | `""` | No | Git repo URL cloned into the notebook on start |
| `enable_auto_shutdown` | bool | `true` | No | Attach the idle-shutdown lifecycle configuration |
| `idle_timeout_minutes` | number | `60` | No | Idle minutes before the notebook stops itself (min 5) |
| `attach_sagemaker_full_access` | bool | `true` | No | Attach `AmazonSageMakerFullAccess` to the execution role |
| `s3_data_bucket_arns` | list(string) | `[]` | No | Bucket ARNs the notebook may read and write |
| `tags` | map(string) | `{}` | No | Extra tags applied to every resource |

## How to Run

1. Create an env0 template pointing at the `sagemaker` folder, IaC type **OpenTofu**
2. Deploy — no variables are required; defaults produce a working notebook
3. Open Jupyter with the presigned URL from the `open_notebook_command` output:
   ```bash
   aws sagemaker create-presigned-notebook-instance-url \
     --notebook-instance-name dev-demo-notebook --region us-east-1
   ```
4. Destroy the environment when you are done (or set a TTL on it)

Deploy takes about 5 minutes; destroy takes about 3.

## Cost

A notebook instance bills for **every hour it is `InService`**, whether anyone is using it or not.

- `ml.t3.medium` ≈ $0.05/hr in `us-east-1` — roughly $36/month if left running
- The KMS key adds ~$1/month while it exists
- The auto-shutdown lifecycle config limits waste but does not delete anything — use an env0 TTL for that

## Security Features

- **Customer-managed KMS key** — encrypts the ML storage volume, with rotation enabled and a key policy scoped to SageMaker plus the execution role
- **IMDSv2 only** — `minimum_instance_metadata_service_version = "2"`, blocking SSRF against the metadata service
- **Root access disabled** — notebook users are not root; lifecycle scripts still run as root, which is what the auto-shutdown job needs
- **Scoped inline policy** — self-stop is limited to this notebook's ARN, S3 access to the buckets you name. Set `attach_sagemaker_full_access = false` to drop the broad managed policy

## Auto-Shutdown

`scripts/on-start.sh` is rendered with `templatefile`, base64-encoded, and attached as the notebook's lifecycle configuration. On every start it writes a small Python script and a `*/5 * * * *` cron entry. The script queries the local Jupyter API (`https://localhost:8443/api/sessions`), and if every kernel reports `idle` with a `last_activity` older than the timeout, it calls `sagemaker:StopNotebookInstance` on itself. Logs land in `/var/log/notebook-autostop.log` on the instance.

To edit the timeout, change `idle_timeout_minutes` and redeploy — the lifecycle config is replaced and the notebook picks it up on its next start.

## VPC Mode

By default the notebook lives in the SageMaker-managed network with direct internet access. To place it in your own VPC:

```hcl
subnet_id              = "subnet-0123456789abcdef0"
security_group_ids     = ["sg-0123456789abcdef0"]
direct_internet_access = "Disabled"   # needs a NAT gateway or VPC endpoints
```

With `direct_internet_access = "Disabled"` and no NAT gateway, the notebook cannot reach SageMaker training or endpoint APIs, or pip. Preconditions on the resource catch the invalid combinations before apply.

## Resources Created

```
aws_sagemaker_notebook_instance
aws_sagemaker_notebook_instance_lifecycle_configuration   (enable_auto_shutdown)
aws_iam_role + aws_iam_role_policy
aws_iam_role_policy_attachment                            (attach_sagemaker_full_access)
aws_kms_key + aws_kms_alias                               (create_kms_key)
```
