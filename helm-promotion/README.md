# helm-promotion

Demonstrates env0's dev → prod Helm promotion pattern using the SaaS runner.

- **dev** deploys automatically on every merge
- **prod** requires a one-click approval gate before env0 triggers the upgrade

The chart is a minimal nginx deployment. Swap it for any real chart — the workflow and approval pattern are the story.

## How it works

```
merge to main
     │
     ▼
 [dev] helm upgrade ──── auto ────► deployed
     │
     ▼
 approval gate  ◄──── reviewer clicks Approve
     │
     ▼
 [prod] helm upgrade ──────────────► deployed
```

## env0 template settings

Create **two templates** in env0, both pointing at this directory:

| Setting           | helm-promotion-dev        | helm-promotion-prod       |
|-------------------|--------------------------|--------------------------|
| Template type     | Helm                     | Helm                     |
| Working directory | `helm-promotion`         | `helm-promotion`         |
| Namespace         | `nginx-dev`              | `nginx-prod`             |
| Values file       | `values-dev.yaml`        | `values-prod.yaml`       |
| Release name      | `nginx-demo`             | `nginx-demo`             |

## env0 variables to configure (both templates)

| Variable          | Value                              | Sensitive |
|-------------------|------------------------------------|-----------|
| `KUBECONFIG_DATA` | base64-encoded kubeconfig          | Yes       |
| `VALUES_FILE`     | `values-dev.yaml` / `values-prod.yaml` | No    |
| `HELM_RELEASE_NAME` | `nginx-demo`                    | No        |
| `HELM_NAMESPACE`  | `nginx-dev` / `nginx-prod`         | No        |

To encode your kubeconfig:
```bash
base64 -i ~/.kube/config | pbcopy
```

## What the environments deploy

| | dev | prod |
|---|---|---|
| Replicas | 1 | 2 |
| Service type | ClusterIP | LoadBalancer |
| Namespace | `nginx-dev` | `nginx-prod` |
