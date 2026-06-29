# ansible-config

Post-deployment Kubernetes configuration via Ansible. Runs after Argo CD is installed and:

- Creates `staging` and `production` namespaces labelled for Argo CD management
- Creates an Argo CD `AppProject` scoped to those namespaces
- Verifies cluster health and prints a summary

## env0 template settings

| Setting | Value |
|---|---|
| Template type | Ansible |
| Working directory | `multi-iac-chaining/ansible-config` |
| Playbook path | `playbook.yml` |

## env0 variables to configure

Set these on the **Ansible Config template** in the env0 UI using the workflow output syntax:

| Variable | Value to set in env0 UI | Description |
|---|---|---|
| `CLUSTER_NAME` | `${env0-workflow:eks-cluster:cluster_name}` | EKS cluster name for kubeconfig |
| `AWS_REGION` | `${env0-workflow:eks-cluster:region}` | AWS region |

> **Note:** The alias `eks-cluster` must match the key in `env0.workflow.yaml`. The upstream environment must have been deployed at least once before the value resolves.

## Dependencies

Requires the `kubernetes.core` Ansible collection. The `before` hook installs it at runtime so no local setup is needed.
