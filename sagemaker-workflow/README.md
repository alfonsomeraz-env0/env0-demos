# SageMaker Workflow (OpenTofu)

Deploys a SageMaker notebook and its supporting infrastructure as an env0 workflow: a data bucket and a network stack in parallel, then the notebook behind an approval gate. All three stages are OpenTofu.

## Stages

```
data ─────┐
          ├──► [approval required] ──► notebook
network ──┘
```

| Stage | Template | Working Directory | Depends On | Approval | Creates |
|---|---|---|---|---|---|
| `data` | `sagemaker-workflow-data` | `sagemaker-workflow/data` | — | No | Versioned, encrypted S3 bucket for datasets and model artifacts |
| `network` | `sagemaker-workflow-network` | `sagemaker-workflow/network` | — | No | VPC, subnet, IGW, egress-only security group |
| `notebook` | `sagemaker-notebook` | `sagemaker` | `data`, `network` | **Yes** | Notebook instance, execution role, KMS key, auto-shutdown |

`data` and `network` have no dependency on each other, so env0 deploys them concurrently — a fan-in graph rather than the straight line in `multi-tier-workflow` and `terragrunt-workflow`.

The notebook stage reuses the standalone [`sagemaker/`](../sagemaker/README.md) demo unchanged. Nothing is duplicated: the same folder works as a standalone template or as a workflow stage.

## Why Approval on the Notebook?

A notebook instance bills for every hour it is `InService`, and it is the only stage here with meaningful running cost. Gating it makes starting the meter a deliberate act, while the bucket and VPC — effectively free — deploy without interruption.

## env0 Setup

### 1. Create the three stage templates

| Template Name | IaC Type | Working Directory |
|---|---|---|
| `sagemaker-workflow-data` | OpenTofu | `sagemaker-workflow/data` |
| `sagemaker-workflow-network` | OpenTofu | `sagemaker-workflow/network` |
| `sagemaker-notebook` | OpenTofu | `sagemaker` |

### 2. Enable Environment Outputs

In the project's **Settings → Policies**, tick **Environment Outputs**. Without it, the notebook stage cannot read the other stages' outputs.

### 3. Create the workflow template

Add a **Workflow** template pointing at `sagemaker-workflow/env0.workflow.yaml`.

### 4. Wire the outputs into the notebook stage

In the workflow template wizard → **Variables** → select the `notebook` sub-environment, and add three variables of type **Environment Output**:

| Variable on `notebook` | Source Alias | Output Name |
|---|---|---|
| `subnet_id` | `network` | `subnet_id` |
| `security_group_ids` | `network` | `security_group_ids` |
| `s3_data_bucket_arns` | `data` | `data_bucket_arns` |

On the first deployment the source stages have never run, so the output dropdown is empty — **free-type** the output names. `needs` guarantees `data` and `network` finish first, so the values resolve by the time the notebook deploys.

> **Lists come through as JSON.** Environment Outputs carry strings only, so `security_group_ids` and `data_bucket_arns` are `jsonencode`d in the source stages. OpenTofu parses a JSON string directly into a `list(string)` input, so the consuming variables need no special handling.

Set `environment` (default `dev`) to the same value on all three stages so resource names line up.

## Alternative: No Templates, Inline VCS

To skip creating the three templates, define the stages inline instead — replace `templateName` with a `vcs` block:

```yaml
environments:
  data:
    name: "SageMaker Data Bucket"
    vcs:
      type: opentofu
      repository: "https://github.com/<your-org>/env0-demos"
      path: "sagemaker-workflow/data"

  network:
    name: "SageMaker Network"
    vcs:
      type: opentofu
      repository: "https://github.com/<your-org>/env0-demos"
      path: "sagemaker-workflow/network"

  notebook:
    name: "SageMaker Notebook"
    vcs:
      type: opentofu
      repository: "https://github.com/<your-org>/env0-demos"
      path: "sagemaker"
    requiresApproval: true
    needs:
      - data
      - network

settings:
  environmentRemovalStrategy: destroy
```

Output-to-variable mapping still has to be configured on the workflow template — the workflow file has no `variables` key.

## Destroy Strategy

```yaml
settings:
  environmentRemovalStrategy: destroy
```

env0 destroys in reverse dependency order, so the notebook goes first and its ENI is gone before the subnet and security group are deleted. Destroying the network stack while the notebook still holds an ENI would leave the security group undeletable.

The data bucket sets `force_destroy = true` so leftover objects do not block teardown. Flip it to `false` for anything you care about.

## Cost

| Stage | Running Cost |
|---|---|
| `data` | Storage only — cents for demo-sized datasets |
| `network` | Free (no NAT gateway — the notebook keeps SageMaker-provided internet access) |
| `notebook` | `ml.t3.medium` ≈ $0.05/hr, plus ~$1/month for the KMS key |

The notebook's auto-shutdown lifecycle config stops the instance after 60 idle minutes, which caps the damage of forgetting about it. It does not delete anything — set a TTL on the workflow environment for that.

## Variables

### `data` stage

| Name | Type | Default | Description |
|---|---|---|---|
| `aws_region` | string | `us-east-1` | AWS region |
| `environment` | string | `dev` | Name prefix — keep consistent across stages |
| `force_destroy` | bool | `true` | Delete objects on destroy |
| `noncurrent_version_expiration_days` | number | `30` | Days before old versions expire |

### `network` stage

| Name | Type | Default | Description |
|---|---|---|---|
| `aws_region` | string | `us-east-1` | AWS region |
| `environment` | string | `dev` | Name prefix — keep consistent across stages |
| `vpc_cidr` | string | `10.42.0.0/16` | VPC CIDR |
| `subnet_cidr` | string | `10.42.1.0/24` | Notebook subnet CIDR |

### `notebook` stage

See [`sagemaker/README.md`](../sagemaker/README.md). Only the three Environment Output variables above need wiring; everything else has a working default.
