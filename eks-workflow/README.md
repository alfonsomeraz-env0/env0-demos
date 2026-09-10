# ACME EKS Demo — Multi-Stage Workflow

Demonstrates an env0 workflow for deploying a Kubernetes platform in two stages: infrastructure first, then applications. Modeled after a realistic enterprise deployment pattern.

## Stages

```
infra ──► [approval required] ──► apps
```

| Stage | Template | IaC Type | Depends On | Approval | Description |
|---|---|---|---|---|---|
| `infra` | `acme-financial-eks-infra` | Terraform | — | No | EKS cluster + VPC + node groups |
| `apps` | `acme-financial-eks-apps` | Kubernetes (native manifests) | `infra` | **Yes** | Namespaces + a sample deployment/service applied directly with `kubectl apply`, no Terraform in the loop |

## Why Approval on Apps?

The apps stage requires manual approval because deploying workloads to a fresh cluster should be a deliberate, human-gated step. This pattern is common in regulated environments (financial services, healthcare) where infrastructure and application changes have separate approval chains.

## env0 Setup

1. Create a **Workflow Template** in env0
2. Point to `eks-workflow/env0.workflow.yaml`
3. Ensure these templates exist in your env0 organization:
   - `acme-financial-eks-infra` — Terraform, path `eks-workflow/infra`
   - `acme-financial-eks-apps` — env0 IaC type **Kubernetes**, path `eks-workflow/apps-k8s` (raw manifests: `namespace.yaml`, `deployment.yaml`, `service.yaml`)
4. Deploy the workflow

> The original Terraform + Helm-provider version of the apps stage is still in `eks-workflow/apps/` for reference, but the registered `acme-financial-eks-apps` template now points at `apps-k8s/` so the stage deploys with env0's native Kubernetes IaC type instead of Terraform.

> **Note:** The EKS infrastructure and application templates are separate repositories/configurations registered in env0. This `env0.workflow.yaml` is the orchestration layer that connects them.

## Destroy Strategy

```yaml
settings:
  environmentRemovalStrategy: destroy
```

Applications are destroyed before the EKS cluster to avoid orphaned Kubernetes resources blocking cluster deletion.

## Use Cases

This pattern applies to any two-tier deployment where:
- Layer 1 creates platform infrastructure (EKS, RDS, networking)
- Layer 2 deploys workloads that depend on that platform
- A human needs to verify layer 1 before layer 2 proceeds
