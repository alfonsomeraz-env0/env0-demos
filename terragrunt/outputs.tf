output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "bucket_id" {
  description = "Name of the S3 bucket"
  value       = module.s3.bucket_id
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = module.ec2.instance_id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = module.ec2.public_ip
}
