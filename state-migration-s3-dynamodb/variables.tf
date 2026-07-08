variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "state_bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name for standalone Terraform state"
  default     = "demo-env0-tfstate"
}

variable "use_dynamodb_locking" {
  type        = bool
  description = "Create a DynamoDB lock table. Set to false to use S3-native locking (use_lockfile = true) instead — requires Terraform/OpenTofu 1.10+ and AWS provider v5+."
  default     = true
}

variable "dynamodb_table_name" {
  type        = string
  description = "DynamoDB table name for state locking (only used when use_dynamodb_locking = true)"
  default     = "demo-env0-tfstate-lock"
}
