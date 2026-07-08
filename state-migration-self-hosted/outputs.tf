output "role_arn" {
  description = "IAM role ARN env0 will assume to read/write your bucket — send this to env0 support"
  value       = module.remote_state_bucket.role_arn
}

output "external_id" {
  description = "Your env0 Organization ID, echoed back for safety — send this to env0 support"
  value       = module.remote_state_bucket.external_id
}

output "region" {
  description = "AWS region of your bucket — send this to env0 support"
  value       = module.remote_state_bucket.region
}

output "bucket_name" {
  description = "Name of the created S3 bucket — send this to env0 support"
  value       = module.remote_state_bucket.bucket_name
}
