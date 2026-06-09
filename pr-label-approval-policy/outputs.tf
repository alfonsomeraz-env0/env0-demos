output "app_bucket_name" {
  description = "Name of the primary application bucket"
  value       = aws_s3_bucket.app.bucket
}

output "logs_bucket_name" {
  description = "Name of the logs bucket (null when create_logs_bucket = false)"
  value       = var.create_logs_bucket ? aws_s3_bucket.logs[0].bucket : null
}
