# ec2-ansible-workflow

Two-stage env0 workflow: Terraform provisions an EC2 instance, then Ansible configures it with nginx.

```
ec2 (Terraform) ──► ansible (Ansible)
```

## Layout

| Folder | IaC type | Purpose |
|---|---|---|
| `terraform-ec2/` | Terraform | Ubuntu 22.04 instance, security group, generated SSH key pair |
| `ansible-config/` | Ansible | Installs nginx and deploys a landing page |
| `workflow/` | Workflow | `env0.workflow.yaml` ordering the two stages |

## env0 templates

| `templateName` | Type | Working directory |
|---|---|---|
| `ec2-ansible-wf-ec2` | Terraform | `ec2-ansible-workflow/terraform-ec2` |
| `ec2-ansible-wf-ansible` | Ansible | `ec2-ansible-workflow/ansible-config` (playbook: `playbook.yml`) |
| (workflow) | Workflow | `ec2-ansible-workflow/workflow` |

## Passing outputs between stages

Enable the project policy **Environment Outputs**. On the workflow template, add these variables to the `ansible` stage as **Environment Output** variables from `ec2`:

| Variable | Source output | Notes |
|---|---|---|
| `INSTANCE_IP` | `instance_ip` | Environment variable |
| `SSH_PRIVATE_KEY` | `private_key_pem` | Environment variable, mark sensitive |

## Variables (Terraform stage)

| Variable | Default |
|---|---|
| `aws_region` | `us-east-2` |
| `instance_type` | `t3.micro` |
| `ssh_cidr` | `0.0.0.0/0` (restrict to the agent egress IP for real use) |

## Requirements

- The env0 agent needs `ansible`, `ssh` and `curl`. The Ansible template type provides Ansible.
- AWS credentials configured on the project.

## Teardown

`environmentRemovalStrategy: destroy` removes both stages in reverse order.
