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

Passed in as environment outputs from upstream workflow environments:

| Variable | Source | Description |
|---|---|---|
| `CLUSTER_NAME` | `terraform-eks` output `cluster_name` | EKS cluster name for kubeconfig |
| `AWS_REGION` | `terraform-eks` output `region` | AWS region |

## Dependencies

Requires the `kubernetes.core` Ansible collection. The `before` hook installs it at runtime so no local setup is needed.
