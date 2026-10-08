# cloud-compass-sg-template

Reusable security group template (no hard-coded values). Defaults reproduce `vpce-sg`: inbound TCP 443 from 10.0.0.0/24 and 20.0.0.0/24, no outbound rules.

## env0 variables

| Variable | Required | Notes |
|---|---|---|
| `vpc_id` | yes | VPC for the security group |
| `name` / `description` | no | default `vpce-sg` |
| `ingress_rules` | no | HCL list of `{from_port, to_port, protocol, cidr_blocks, description?}` |
| `tags` | no | extra tags; `Name` comes from `name` |
| `region` | no | default `us-east-1` |
