output "security_group_id" {
  value = aws_security_group.vpce_sg2.id
}

output "vpc_cidr" {
  value = data.aws_vpc.vpce_demo.cidr_block
}
