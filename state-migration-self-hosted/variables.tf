variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "external_id" {
  type        = string
  description = "Your env0 Organization ID (Organization Settings). Scopes the IAM trust policy so only your org's env0 backend can assume the role."
}

variable "state_bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name that will hold your org's env0-managed Terraform state"
  default     = "demo-env0-self-hosted-state"
}
