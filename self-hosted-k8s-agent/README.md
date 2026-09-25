# env0 Self-Hosted Kubernetes Agent on EKS

Provisions an EKS cluster on AWS and installs env0's self-hosted Kubernetes
agent onto it via Helm, in two stages:

```
infra ──► apps
```

| Stage | IaC Type | Path | Provisions |
|---|---|---|---|
| `infra` | Terraform | `infra/` | VPC (public + private subnets, single NAT), EKS cluster, managed node group |
| `apps` | Terraform | `apps/` | `env0-agent` namespace + Helm release |

## Before you deploy

**1. Rotate the agent token.** If an agent access token was ever pasted into a
chat, ticket, or shared doc, treat it as compromised. Generate a new one in
env0: **Settings → Agents → your self-hosted agent**.

**2. Store the token in AWS Secrets Manager yourself, outside of any
AI-assisted session** (i.e. run this in your own terminal, don't paste the
token into a chat tool):

```bash
aws secretsmanager create-secret \
  --name env0/self-hosted-agent/access-token \
  --secret-string "<paste the NEW token here, in your own terminal>"
```

The `apps` stage reads this secret through the Terraform AWS provider
(`data.aws_secretsmanager_secret_version`) and passes it to Helm via
`set_sensitive`, so the value is never printed in plan/apply output and never
needs to be typed into a chart command directly. The token does land in
Terraform state, so use an encrypted remote state backend and restrict who
can read it — this is standard for any Terraform-managed secret.

**3. Get the real Helm chart repository URL from the env0 UI**
(Settings → Agents → self-hosted agent → the setup instructions show the
exact `helm repo add` URL and chart name). The link
`docs.envzero.com` referenced when this demo was requested does not match
env0's actual docs domain (`docs.env0.com`) — verify the source before
trusting any setup instructions from it. Set the confirmed URL as
`agent_chart_repository` (see below).

## Variables

`infra/` (all optional, sensible defaults):
- `aws_region` (default `us-east-2`)
- `project_name` (default `env0-self-hosted-agent`)
- `vpc_cidr`, `cluster_version`, `node_instance_types`, `node_desired_size/min_size/max_size`
- `cluster_public_access_cidrs` — lock this down to your office/VPN CIDR for anything beyond a throwaway demo

`apps/`:
- `eks_cluster_name` — must match the `infra` stage's cluster name output
- `agent_chart_repository` — **required**, no default (see step 3 above)
- `agent_chart_version` — pin this for anything beyond a one-off demo
- `agent_token_secret_id` (default `env0/self-hosted-agent/access-token`)

## env0 Setup

Register three templates in this order (the workflow template resolves the
other two by **name**, so they must exist first):

| Template | IaC Type | Path |
|---|---|---|
| `env0-self-hosted-agent-infra` | Terraform | `self-hosted-k8s-agent/infra` |
| `env0-self-hosted-agent-apps` | Terraform | `self-hosted-k8s-agent/apps` |
| `env0-self-hosted-agent-workflow` | **Workflow** | `self-hosted-k8s-agent` (the directory containing `env0.workflow.yaml`, not the file itself) |

Then:
1. Set `agent_chart_repository` (and any overrides) as variables on the `apps` template
2. Deploy the workflow template — it will run `infra` first, then `apps`

## Local run

```bash
cd self-hosted-k8s-agent/infra
terraform init && terraform apply

cd ../apps
terraform init && terraform apply \
  -var="eks_cluster_name=$(terraform -chdir=../infra output -raw eks_cluster_name)" \
  -var="agent_chart_repository=<url from env0 UI>"
```

## Security notes

- Nodes run in private subnets behind a NAT gateway — no direct internet inbound.
- IMDSv2 is required on all nodes (blocks the common SSRF-to-credential-theft path).
- EKS control plane logging (`api`, `audit`, `authenticator`) ships to CloudWatch.
- The agent access token never appears in Terraform plan output, env0 CLI
  output, or a Helm command — it's resolved from Secrets Manager at apply
  time and marked sensitive throughout.
