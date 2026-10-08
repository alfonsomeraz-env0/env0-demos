variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_id" {
  type    = string
  default = "vpc-0502143b40121debe"
}

variable "subnet_id" {
  type    = string
  default = "subnet-028fe9ae2d562cdac"
}

variable "security_group_id" {
  description = "Existing security group to import"
  type        = string
  default     = "sg-0aef10234f2b580b7"
}

variable "vpc_endpoint_id" {
  description = "Existing VPC endpoint to import"
  type        = string
  default     = "vpce-0b61a89efc3e50614"
}

variable "endpoint_service_name" {
  type    = string
  default = "com.amazonaws.vpce.us-east-1.vpce-svc-09143d1e626de2f04"
}
