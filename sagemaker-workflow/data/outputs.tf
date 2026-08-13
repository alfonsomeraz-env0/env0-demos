output "data_bucket_name" {
  description = "Name of the dataset bucket"
  value       = aws_s3_bucket.data.id
}

output "data_bucket_arn" {
  description = "ARN of the dataset bucket"
  value       = aws_s3_bucket.data.arn
}

# env0 Environment Outputs are strings only, so list-typed consumers get JSON.
# OpenTofu parses a JSON string straight into a list(string) input variable.
output "data_bucket_arns" {
  description = "JSON-encoded list — feeds the notebook stage's s3_data_bucket_arns"
  value       = jsonencode([aws_s3_bucket.data.arn])
}
