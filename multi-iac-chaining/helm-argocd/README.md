# helm-argocd

Deploys Argo CD onto the EKS cluster provisioned by the `terraform-eks` module using the official `argo-cd` Helm chart.

## env0 template settings

| Setting | Value |
|---|---|
| Template type | Helm |
| Working directory | `multi-iac-chaining/helm-argocd` |
| Helm chart | `argo-cd` |
| Helm repo URL | `https://argoproj.github.io/argo-helm` |
| Namespace | `argocd` |
| Values file | `values.yaml` |

## env0 variables to configure

These are set as environment outputs from the upstream `terraform-eks` environment in the workflow:

| Variable | Source | Description |
|---|---|---|
| `CLUSTER_NAME` | `terraform-eks` output `cluster_name` | EKS cluster name for kubeconfig |
| `AWS_REGION` | `terraform-eks` output `region` | AWS region |

AWS credentials must be configured on the env0 template so the `before` hook can call `aws eks update-kubeconfig`.

## What gets deployed

- Argo CD server (single replica, demo-sized)
- LoadBalancer service with internet-facing NLB
- Redis (embedded)
- Dex and Notifications disabled for simplicity

After deployment the `after` hook prints the LoadBalancer hostname and the initial admin password.
