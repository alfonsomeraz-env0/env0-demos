variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name — must match the other workflow stages so names line up"
  type        = string
  default     = "dev"
}

variable "force_destroy" {
  description = "Delete objects when the bucket is destroyed. Keep true for demos, false for anything real."
  type        = bool
  default     = true
}

variable "noncurrent_version_expiration_days" {
  description = "Days before noncurrent object versions expire"
  type        = number
  default     = 30
}
