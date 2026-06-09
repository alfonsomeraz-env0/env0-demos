variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "bucket_prefix" {
  description = "Prefix for bucket names (must be globally unique across the demo)"
  type        = string
}

variable "create_logs_bucket" {
  description = "Set to false on a re-deploy to produce a delete action and trigger the deletion-approval branch"
  type        = bool
  default     = true
}
