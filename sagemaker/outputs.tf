output "notebook_instance_name" {
  description = "Name of the SageMaker notebook instance"
  value       = aws_sagemaker_notebook_instance.this.name
}

output "notebook_instance_arn" {
  description = "ARN of the SageMaker notebook instance"
  value       = aws_sagemaker_notebook_instance.this.arn
}

output "notebook_url" {
  description = "Jupyter host for the notebook (open it via a presigned console URL, not directly)"
  value       = aws_sagemaker_notebook_instance.this.url
}

output "aws_region" {
  description = "Region the notebook lives in — needed by every SageMaker CLI call against it"
  value       = var.aws_region
}

output "name_suffix" {
  description = "Suffix applied to every resource name (empty when neither unique_suffix nor append_random_suffix is used)"
  value       = local.suffix
}

output "execution_role_arn" {
  description = "ARN of the notebook execution role"
  value       = aws_iam_role.notebook.arn
}

output "kms_key_arn" {
  description = "ARN of the KMS key encrypting the ML storage volume (empty if unencrypted by a customer-managed key)"
  value       = local.kms_key_arn
}

output "lifecycle_config_name" {
  description = "Name of the auto-shutdown lifecycle configuration (empty when disabled)"
  value       = var.enable_auto_shutdown ? aws_sagemaker_notebook_instance_lifecycle_configuration.auto_shutdown[0].name : ""
}

output "open_notebook_command" {
  description = "AWS CLI command that generates a presigned Jupyter URL"
  value       = "aws sagemaker create-presigned-notebook-instance-url --notebook-instance-name ${aws_sagemaker_notebook_instance.this.name} --region ${var.aws_region}"
}
