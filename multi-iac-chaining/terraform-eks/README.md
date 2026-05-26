# terraform-eks

Provisions an EKS cluster on AWS using the `terraform-aws-modules/eks` and `terraform-aws-modules/vpc` community modules.

## What it provisions

| Resource | Details |
|---|---|
| VPC | `/16` CIDR with 3 public + 3 private subnets across AZs |
| NAT Gateway | Single NAT gateway (cost-optimised for demos) |
| EKS Cluster | Managed control plane, public API endpoint |
| Node Group | `t3.medium` managed node group (auto-scaling) |

## env0 template settings

| Setting | Value |
|---|---|
| Template type | Terraform |
| Terraform version | >= 1.5 |
| Working directory | `multi-iac-chaining/terraform-eks` |
| AWS credentials | Configure via env0 cloud credentials |

## env0 variables to configure

| Variable | Description | Default |
|---|---|---|
| `region` | AWS region | `us-east-1` |
| `cluster_name` | EKS cluster name | `multi-iac-demo` |
| `k8s_version` | Kubernetes version | `1.30` |
| `node_instance_type` | Worker node EC2 type | `t3.medium` |
| `node_desired_count` | Desired node count | `2` |

## Outputs consumed by downstream environments

After deployment, the following outputs are available to reference from dependent workflow environments:

- `cluster_name` — passed to Helm and Ansible as `CLUSTER_NAME`
- `region` — passed as `AWS_REGION`
