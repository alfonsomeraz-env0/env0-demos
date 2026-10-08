variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_id" {
  description = "Manually created VPC that holds the security group"
  type        = string
  default     = "vpc-09ba80173d165f331"
}
