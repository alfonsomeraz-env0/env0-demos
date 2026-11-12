output "instance_ip" {
  description = "Public IP of the instance"
  value       = aws_instance.web.public_ip
}

output "private_key_pem" {
  description = "SSH private key for Ansible"
  value       = tls_private_key.ansible.private_key_openssh
  sensitive   = true
}

output "aws_region" {
  value = var.aws_region
}
