variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "demo-instance"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be launched"
  type        = string
}

variable "security_group_ids" {
  description = "JSON-encoded list of security group IDs to attach to the instance, e.g. [\"sg-0123\"]. Empty string uses the VPC's default security group."
  type        = string
  default     = ""
}

variable "root_volume_size" {
  description = "Desired root volume size in GB (will be at least as large as the AMI snapshot)"
  type        = number
  default     = 20
}
