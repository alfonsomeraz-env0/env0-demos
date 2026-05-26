# workflow

Orchestrates the three multi-IAC environments using `env0.workflow.yaml`.

## Deployment order

```
eks-cluster  ──► (approval gate) ──► argocd  ──► k8s-config
```

| Step | Template | IAC type | Waits for |
|---|---|---|---|
| `eks-cluster` | `multi-iac-eks-cluster` | Terraform | — |
| `argocd` | `multi-iac-argocd` | Helm | `eks-cluster` + approval |
| `k8s-config` | `multi-iac-ansible-config` | Ansible | `argocd` |

The approval gate before `argocd` gives an operator a chance to review the cluster before committing to the Helm and Ansible steps.

## env0 template settings

| Setting | Value |
|---|---|
| Template type | Workflow |
| Working directory | `multi-iac-chaining/workflow` |

## Template names

The `templateName` values in `env0.workflow.yaml` must match templates you register in env0. Suggested names:

| `templateName` | Points to folder |
|---|---|
| `multi-iac-eks-cluster` | `multi-iac-chaining/terraform-eks` |
| `multi-iac-argocd` | `multi-iac-chaining/helm-argocd` |
| `multi-iac-ansible-config` | `multi-iac-chaining/ansible-config` |

## Teardown

`environmentRemovalStrategy: destroy` ensures all three environments are destroyed in reverse dependency order when the workflow environment is removed from env0.
