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
| **IaC Type** | OpenTofu (Terraform also works) |
| **IaC Version** | OpenTofu >= 1.6.0, or Terraform >= 1.2.0 |
| **AWS Provider** | >= 6.19.0 |
| **Working Directory** | `sagemaker` |

The code is plain HCL — the `required_version` floor comes from the `lifecycle` preconditions, not from OpenTofu. It is validated on both OpenTofu and Terraform 1.5.7 (env0's default Terraform version), so a template created with the wrong IaC type still deploys. Set the type to **OpenTofu** if you want the demo to actually exercise OpenTofu.

> **Provider floor matters here.** `notebook-al2023-v1` was only added to the AWS provider's `platform_identifier` validation in **6.19.0**; the 5.x line rejects it before the API is ever called. If you must stay on an older provider, set `platform_identifier = "notebook-al2-v3"`.

Custom flow format is identical between Terraform and OpenTofu, so `env0.yaml` still uses the `terraformInit` / `terraformApply` / `terraformDestroy` step names. The hooks resolve `tofu` or `terraform` at runtime, so the same file works under either IaC type.

## Variables

| Name | Type | Default | Required | Description |
|---|---|---|---|---|
| `aws_region` | string | `us-east-1` | No | AWS region |
| `environment` | string | `dev` | No | Environment name — prefixes every resource name |
| `notebook_name` | string | `demo-notebook` | No | Notebook name (middle of the composed name) |
| `append_random_suffix` | bool | `true` | No | Append a generated 6-char suffix so one template can back many notebooks |
| `unique_suffix` | string | `""` | No | Fixed suffix instead of a generated one |
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
3. Open Jupyter by running the `open_notebook_command` output verbatim — it already contains the generated instance name:
   ```bash
   aws sagemaker create-presigned-notebook-instance-url \
     --notebook-instance-name dev-demo-notebook-k3f9qz --region us-east-1
   ```
4. Destroy the environment when you are done (or set a TTL on it)

Deploy takes about 5 minutes; destroy takes about 3.

## Deploying Multiple Notebooks

Every resource here is named after the notebook, so deploying this template twice with the same variables collides — the IAM role, lifecycle config, and KMS alias are all account-wide unique names.

By default the composed name gets a generated 6-character suffix:

```
<environment>-<notebook_name>-<suffix>     dev-demo-notebook-k3f9qz
```

The suffix is generated once and kept in that environment's state, so it is stable across redeploys of the same environment and different between environments. Deploy the template as many times as you like with no variable changes at all.

To control the names instead, set `unique_suffix` per environment — the env0 environment name is a good choice:

```hcl
unique_suffix = "team-a"   # dev-demo-notebook-team-a
```

Or turn suffixes off entirely with `append_random_suffix = false`, which reproduces the original single-notebook naming. `unique_suffix` wins over `append_random_suffix` when both are set.

Names are validated at **plan** time, before anything is created:

| Check | Limit |
|---|---|
| Composed name length | 49 chars — `-execution-role` against IAM's 64 and `-auto-shutdown` against SageMaker's 63 both leave exactly that |
| Character set | Alphanumeric with single dashes, matching SageMaker's pattern |

> **Upgrading an existing environment.** `append_random_suffix` defaults to `true`, so an environment deployed before this change will plan to rename — and therefore replace — its notebook and role. To keep an existing environment exactly as it is, set `append_random_suffix = false` on it. New environments can take the default.

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

`scripts/on-start.sh` is rendered with `templatefile`, base64-encoded, and attached as the notebook's lifecycle configuration. On every start it writes a small Python script and a `*/5 * * * *` cron entry. Logs land in `/var/log/notebook-autostop.log` on the instance.

Each run asks the local Jupyter API (`https://localhost:8443/api/`) for three things and takes the **most recent** of them as the last activity:

| Signal | Endpoint | Why |
|---|---|---|
| Server start time | `status.started` | Floor — gives a notebook nobody has opened yet a full idle window instead of stopping it on the first tick after boot |
| Kernel activity | `sessions[].kernel.last_activity` | Normal notebook use |
| Terminal activity | `terminals[].last_activity` | Terminal-only sessions with no kernel |

It stops the instance only if that most recent activity is older than the timeout. A `busy` kernel always blocks shutdown, and an unreachable Jupyter API leaves the notebook running rather than guessing.

The server's own `last_activity` field is deliberately unused: Jupyter refreshes it on authenticated API requests, so the script's polling could keep resetting it and prevent shutdown entirely.

Open connections are ignored — an abandoned browser tab does not keep the instance alive. Editing files without ever starting a kernel or terminal is the one case that can still be cut short; opening a notebook creates a kernel, which is tracked.

To edit the timeout, change `idle_timeout_minutes` and redeploy — the lifecycle config is replaced and the notebook picks it up on its next start.

### Restarting a Stopped Notebook

Auto-shutdown stops the instance, it does not delete it. The volume, files, and lifecycle config survive:

```bash
NOTEBOOK=$(tofu output -raw notebook_instance_name)   # or copy it from the env0 outputs
aws sagemaker start-notebook-instance --notebook-instance-name "$NOTEBOOK" --region us-east-1
aws sagemaker wait notebook-instance-in-service --notebook-instance-name "$NOTEBOOK" --region us-east-1
aws sagemaker create-presigned-notebook-instance-url --notebook-instance-name "$NOTEBOOK" --region us-east-1
```

`create-presigned-notebook-instance-url` fails with `NotebookInstance must be in InService state` while the instance is stopped — start it first.

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
random_string                                             (append_random_suffix)
```
