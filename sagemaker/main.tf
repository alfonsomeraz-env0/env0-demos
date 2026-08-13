terraform {
  required_version = ">= 1.6.0" # OpenTofu 1.6 is the first release

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(
      {
        Environment = var.environment
        ManagedBy   = "OpenTofu"
        Demo        = "sagemaker-notebook"
      },
      var.tags,
    )
  }
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  name = "${var.environment}-${var.notebook_name}"

  # Built from account/region/name rather than the resource attribute so the
  # execution role policy can reference the notebook without a dependency cycle.
  notebook_arn = "arn:${data.aws_partition.current.partition}:sagemaker:${var.aws_region}:${data.aws_caller_identity.current.account_id}:notebook-instance/${local.name}"

  kms_key_arn = var.create_kms_key ? aws_kms_key.notebook[0].arn : var.kms_key_arn
  use_vpc     = var.subnet_id != ""
}

# ── KMS — encrypts the ML storage volume ─────────────────────────────────────

resource "aws_kms_key" "notebook" {
  count = var.create_kms_key ? 1 : 0

  description             = "Encrypts the ML storage volume for ${local.name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms[0].json

  tags = { Name = "${local.name}-volume-key" }
}

resource "aws_kms_alias" "notebook" {
  count = var.create_kms_key ? 1 : 0

  name          = "alias/${local.name}"
  target_key_id = aws_kms_key.notebook[0].key_id
}

data "aws_iam_policy_document" "kms" {
  count = var.create_kms_key ? 1 : 0

  # Lets IAM policies in this account govern the key (standard root statement).
  statement {
    sid       = "EnableAccountAccess"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  # SageMaker attaches the encrypted volume on behalf of the notebook.
  statement {
    sid = "AllowSageMakerVolumeEncryption"

    actions = [
      "kms:CreateGrant",
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*",
    ]

    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.notebook.arn]
    }
  }
}

# ── IAM — notebook execution role ────────────────────────────────────────────

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "notebook" {
  name               = "${local.name}-execution-role"
  description        = "Execution role for the ${local.name} SageMaker notebook instance"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = { Name = "${local.name}-execution-role" }
}

# Broad by design — it is what the SageMaker console suggests and what most
# example notebooks expect. Turn it off for a least-privilege demo.
resource "aws_iam_role_policy_attachment" "sagemaker_full_access" {
  count = var.attach_sagemaker_full_access ? 1 : 0

  role       = aws_iam_role.notebook.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSageMakerFullAccess"
}

data "aws_iam_policy_document" "notebook" {
  statement {
    sid = "NotebookLogs"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/sagemaker/*"]
  }

  # The auto-shutdown cron job stops the notebook it is running on.
  dynamic "statement" {
    for_each = var.enable_auto_shutdown ? [1] : []

    content {
      sid = "SelfStopWhenIdle"

      actions = [
        "sagemaker:DescribeNotebookInstance",
        "sagemaker:StopNotebookInstance",
      ]

      resources = [local.notebook_arn]
    }
  }

  dynamic "statement" {
    for_each = length(var.s3_data_bucket_arns) > 0 ? [1] : []

    content {
      sid       = "ListDataBuckets"
      actions   = ["s3:GetBucketLocation", "s3:ListBucket"]
      resources = var.s3_data_bucket_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.s3_data_bucket_arns) > 0 ? [1] : []

    content {
      sid       = "ReadWriteDataObjects"
      actions   = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
      resources = [for arn in var.s3_data_bucket_arns : "${arn}/*"]
    }
  }

  dynamic "statement" {
    for_each = local.kms_key_arn != "" ? [1] : []

    content {
      sid = "UseVolumeKey"

      actions = [
        "kms:CreateGrant",
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*",
      ]

      resources = [local.kms_key_arn]
    }
  }
}

resource "aws_iam_role_policy" "notebook" {
  name   = "${local.name}-notebook-policy"
  role   = aws_iam_role.notebook.id
  policy = data.aws_iam_policy_document.notebook.json
}

# ── Lifecycle configuration — stop the notebook once it goes idle ────────────

resource "aws_sagemaker_notebook_instance_lifecycle_configuration" "auto_shutdown" {
  count = var.enable_auto_shutdown ? 1 : 0

  name = "${local.name}-auto-shutdown"

  on_start = base64encode(templatefile("${path.module}/scripts/on-start.sh", {
    idle_timeout_minutes = var.idle_timeout_minutes
  }))
}

# ── Notebook instance ────────────────────────────────────────────────────────

resource "aws_sagemaker_notebook_instance" "this" {
  name                    = local.name
  role_arn                = aws_iam_role.notebook.arn
  instance_type           = var.instance_type
  volume_size             = var.volume_size
  platform_identifier     = var.platform_identifier
  kms_key_id              = local.kms_key_arn != "" ? local.kms_key_arn : null
  root_access             = var.root_access
  direct_internet_access  = var.direct_internet_access
  subnet_id               = local.use_vpc ? var.subnet_id : null
  security_groups         = local.use_vpc ? var.security_group_ids : null
  default_code_repository = var.default_code_repository != "" ? var.default_code_repository : null
  lifecycle_config_name   = var.enable_auto_shutdown ? aws_sagemaker_notebook_instance_lifecycle_configuration.auto_shutdown[0].name : null

  instance_metadata_service_configuration {
    minimum_instance_metadata_service_version = "2"
  }

  tags = { Name = local.name }

  lifecycle {
    precondition {
      condition     = var.direct_internet_access == "Enabled" || local.use_vpc
      error_message = "direct_internet_access = \"Disabled\" is only valid when subnet_id is set."
    }

    precondition {
      condition     = !local.use_vpc || length(var.security_group_ids) > 0
      error_message = "security_group_ids must contain at least one security group when subnet_id is set."
    }
  }

  # The notebook boots and runs its lifecycle script immediately, so the role
  # needs its permissions in place before the instance exists.
  depends_on = [
    aws_iam_role_policy.notebook,
    aws_iam_role_policy_attachment.sagemaker_full_access,
  ]
}
