# helm-workflows

env0 demos for Helm charts and workflows. Reuses the EKS cluster from `../helm-promotion/cluster`.

```
helm-workflows/
├── charts/demo-web/            # Helm chart (nginx + ConfigMap)
├── terraform/app-resources/    # S3 bucket, outputs bucket_name
├── workflows/                  # Terraform -> Helm workflow
└── approvals-rig/              # requiresApproval test rig (no cloud needed)
```

## Templates (project: Dev - ADM)

| Template | Type | Repo path | Notes |
|---|---|---|---|
| `helm-demo-cluster` | Terraform | `helm-promotion/cluster` | `region=us-east-2`, `cluster_name=helm-demo` |
| `demo-web-git` | Helm | `helm-workflows/charts/demo-web` | Kubernetes credential required |
| `app-resources-tf` | Terraform | `helm-workflows/terraform/app-resources` | AWS credential |
| `demo-web-workflow` | Workflow | `helm-workflows/workflows` | |
| `noop` | Terraform 1.4+ | `helm-workflows/approvals-rig/noop` | |
| `approvals-rig` | Workflow | `helm-workflows/approvals-rig` | |

Project policies: Environment Outputs on, Default auto-approve off.

## Helm variables (on `demo-web-git`)

| Key | Value |
|---|---|
| `ENV0_HELM_VALUES_FILES` | `values-dev.yaml` |
| `ENV0_HELM_SET_replicaCount` | `2` |
| `ENV0_HELM_CLI_ARGS_upgrade` | `--create-namespace --timeout 5m` |

## Demo 2: Terraform to Helm

On the workflow template, Variables step, select `web` and add an Environment Output variable:
key `ENV0_HELM_SET_config.bucketName`, source `app-resources`, output `bucket_name`.

Verify: `kubectl get cm demo-web-config -n demo -o yaml`

## Approvals rig

Runs 1 and 2: delete the `requiresApproval` lines. Run 2 adds `ENV0_REQUIRES_APPROVAL=false` on svc-a/b/c.
Run 3: file as committed. Run 4: repeat 2 and 3 with an approval policy on the project.
