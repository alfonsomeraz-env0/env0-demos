variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g. dev, staging, prod) — prefixes every resource name"
  type        = string
  default     = "dev"
}

variable "notebook_name" {
  description = "Notebook instance name, prefixed with the environment name"
  type        = string
  default     = "demo-notebook"

  validation {
    condition     = can(regex("^[a-zA-Z0-9](-*[a-zA-Z0-9])*$", var.notebook_name))
    error_message = "notebook_name must be alphanumeric with single dashes between characters."
  }
}

variable "instance_type" {
  description = "ML compute instance type for the notebook (ml.t3.medium is the cheapest general-purpose option)"
  type        = string
  default     = "ml.t3.medium"
}

variable "volume_size" {
  description = "Size of the ML storage volume in GB"
  type        = number
  default     = 5

  validation {
    condition     = var.volume_size >= 5 && var.volume_size <= 16384
    error_message = "volume_size must be between 5 and 16384 GB."
  }
}

variable "platform_identifier" {
  description = "Notebook runtime platform"
  type        = string
  default     = "notebook-al2023-v1"

  validation {
    condition     = contains(["notebook-al2-v2", "notebook-al2-v3", "notebook-al2023-v1"], var.platform_identifier)
    error_message = "platform_identifier must be notebook-al2-v2, notebook-al2-v3, or notebook-al2023-v1 (earlier platforms do not support IMDSv2-only)."
  }
}

variable "root_access" {
  description = "Whether notebook users get root access. Lifecycle scripts always run as root regardless."
  type        = string
  default     = "Disabled"

  validation {
    condition     = contains(["Enabled", "Disabled"], var.root_access)
    error_message = "root_access must be Enabled or Disabled."
  }
}

variable "direct_internet_access" {
  description = "Whether SageMaker gives the notebook internet access. Disabling it requires subnet_id plus a NAT gateway or VPC endpoints."
  type        = string
  default     = "Enabled"

  validation {
    condition     = contains(["Enabled", "Disabled"], var.direct_internet_access)
    error_message = "direct_internet_access must be Enabled or Disabled."
  }
}

variable "subnet_id" {
  description = "Optional subnet ID to attach the notebook to your own VPC. Leave empty to use the SageMaker-managed network."
  type        = string
  default     = ""
}

variable "security_group_ids" {
  description = "Security group IDs for the VPC network interface. Required when subnet_id is set (max 5)."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.security_group_ids) <= 5
    error_message = "SageMaker accepts at most 5 security groups."
  }
}

variable "create_kms_key" {
  description = "Create a customer-managed KMS key for the ML storage volume"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "ARN of an existing KMS key to encrypt the ML storage volume. Only used when create_kms_key is false."
  type        = string
  default     = ""
}

variable "default_code_repository" {
  description = "Optional Git repository URL cloned into the notebook on start (e.g. https://github.com/aws/amazon-sagemaker-examples.git)"
  type        = string
  default     = ""
}

variable "enable_auto_shutdown" {
  description = "Attach a lifecycle configuration that stops the notebook once its kernels go idle"
  type        = bool
  default     = true
}

variable "idle_timeout_minutes" {
  description = "Minutes of kernel inactivity before the notebook stops itself"
  type        = number
  default     = 60

  validation {
    condition     = var.idle_timeout_minutes >= 5
    error_message = "idle_timeout_minutes must be at least 5 (the idle check runs every 5 minutes)."
  }
}

variable "attach_sagemaker_full_access" {
  description = "Attach the AWS-managed AmazonSageMakerFullAccess policy to the execution role. Set to false for a least-privilege demo."
  type        = bool
  default     = true
}

variable "s3_data_bucket_arns" {
  description = "Bucket ARNs the notebook may read and write (list on the bucket, get/put/delete on its objects)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags applied to every resource"
  type        = map(string)
  default     = {}
}
