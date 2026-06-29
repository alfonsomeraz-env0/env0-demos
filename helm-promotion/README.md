# helm-promotion

Self-contained demo: provisions a minimal EKS cluster, then promotes an nginx Helm chart from dev to prod with an approval gate — all via env0's SaaS runner.

```
EKS Cluster (Terraform)
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

## Templates to create in env0

### helm-promotion-cluster

| Setting           | Value                          |
|-------------------|-------------------------------|
| Template type     | Terraform                     |
| Working directory | `helm-promotion/cluster`      |
| Revision          | `main`                        |

Variables:

| Key            | Value          |
|----------------|----------------|
| `region`       | `us-east-2`    |
| `cluster_name` | `helm-promotion` |

### helm-promotion-dev

| Setting           | Value                    |
|-------------------|--------------------------|
| Template type     | Helm                     |
| Working directory | `helm-promotion`         |
| Namespace         | `nginx-dev`              |
| Values file       | `values-dev.yaml`        |
| Release name      | `nginx-demo`             |

Variables (set via workflow output from `cluster`):

| Key                | Value                                       |
|--------------------|---------------------------------------------|
| `CLUSTER_NAME`     | `${env0-workflow:cluster:cluster_name}`     |
| `AWS_REGION`       | `${env0-workflow:cluster:region}`           |
| `VALUES_FILE`      | `values-dev.yaml`                           |
| `HELM_RELEASE_NAME`| `nginx-demo`                                |
| `HELM_NAMESPACE`   | `nginx-dev`                                 |

### helm-promotion-prod

Same as dev, with:

| Setting     | Value              |
|-------------|--------------------|
| Namespace   | `nginx-prod`       |
| Values file | `values-prod.yaml` |

Variables:

| Key                | Value                                       |
|--------------------|---------------------------------------------|
| `CLUSTER_NAME`     | `${env0-workflow:cluster:cluster_name}`     |
| `AWS_REGION`       | `${env0-workflow:cluster:region}`           |
| `VALUES_FILE`      | `values-prod.yaml`                          |
| `HELM_RELEASE_NAME`| `nginx-demo`                                |
| `HELM_NAMESPACE`   | `nginx-prod`                                |

## What each environment deploys

|             | dev         | prod          |
|-------------|-------------|---------------|
| Replicas    | 1           | 2             |
| Service     | ClusterIP   | LoadBalancer  |
| Namespace   | `nginx-dev` | `nginx-prod`  |

## Cluster specs

- EKS 1.30, single `t3.medium` node (scales to 2)
- Public API endpoint (reachable from env0 SaaS runner)
- No KMS, no CloudWatch logs — minimal footprint for demo
