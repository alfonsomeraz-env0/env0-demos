variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "bucket_name" {
  type        = string
  description = "S3 bucket name for Terragrunt remote state. Leave empty to auto-generate a globally-unique name (recommended — S3 bucket names are unique account-wide, so a fixed name collides on repeat deploys)."
  default     = ""
}

variable "dynamodb_table_name" {
  type        = string
  description = "DynamoDB table name for state locking. Leave empty to auto-generate a unique name matching bucket_name."
  default     = ""
}
