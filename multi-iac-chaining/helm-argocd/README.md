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

Set these on the **ArgoCD template** in the env0 UI. Use the workflow output syntax so env0 injects the values from the upstream `eks-cluster` sub-environment automatically:

| Variable | Value to set in env0 UI | Description |
|---|---|---|
| `CLUSTER_NAME` | `${env0-workflow:eks-cluster:cluster_name}` | EKS cluster name for kubeconfig |
| `AWS_REGION` | `${env0-workflow:eks-cluster:region}` | AWS region |

> **Note:** The source sub-environment alias (`eks-cluster`) must match the key used in `env0.workflow.yaml`, not the display name. The upstream environment must have been deployed at least once before the value resolves.

AWS credentials must also be configured on the template so the `before` hook can call `aws eks update-kubeconfig`.

## What gets deployed

- Argo CD server (single replica, demo-sized)
- LoadBalancer service with internet-facing NLB
- Redis (embedded)
- Dex and Notifications disabled for simplicity

After deployment the `after` hook prints the LoadBalancer hostname and the initial admin password.
