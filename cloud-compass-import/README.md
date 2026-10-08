# cloud-compass-import

Brings two ClickOps-created AWS resources under Terraform management using `import` blocks:

- Security group `vpce-sg` (inbound TCP 443 from 10.0.0.0/24, no outbound rules)
- Interface VPC endpoint `test-vpce1` (partner PrivateLink service, private DNS enabled)

## env0 setup

- Template type: Terraform, path `cloud-compass-import`
- Project: Dev - ADM, with an AWS credential for the account that owns the resources
- All variables have defaults matching the demo resources (us-east-1)

## Day 2

Add a second `ingress` block (20.0.0.0/24, TCP 443) to `aws_security_group.vpce_sg`, push, and redeploy.
