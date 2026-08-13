output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "subnet_id" {
  description = "Subnet for the notebook ENI — feeds the notebook stage's subnet_id"
  value       = aws_subnet.notebook.id
}

output "security_group_id" {
  description = "Security group for the notebook ENI"
  value       = aws_security_group.notebook.id
}

# env0 Environment Outputs are strings only, so list-typed consumers get JSON.
# OpenTofu parses a JSON string straight into a list(string) input variable.
output "security_group_ids" {
  description = "JSON-encoded list — feeds the notebook stage's security_group_ids"
  value       = jsonencode([aws_security_group.notebook.id])
}
