terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Primary bucket — always present.
resource "aws_s3_bucket" "app" {
  bucket = "${var.bucket_prefix}-app-${var.environment}"

  tags = {
    Name        = "${var.bucket_prefix}-app-${var.environment}"
    Environment = var.environment
    ManagedBy   = "env0"
    Demo        = "pr-label-approval-policy"
    CostCenter  = "demo"
    Team        = "platform"
  }
}

resource "aws_s3_bucket_versioning" "app" {
  bucket = aws_s3_bucket.app.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "app" {
  bucket = aws_s3_bucket.app.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Optional logs bucket — toggle `create_logs_bucket = false` to produce a
# `delete` action in the plan and trigger the deletion-approval branch live.
resource "aws_s3_bucket" "logs" {
  count  = var.create_logs_bucket ? 1 : 0
  bucket = "${var.bucket_prefix}-logs-${var.environment}"

  tags = {
    Name        = "${var.bucket_prefix}-logs-${var.environment}"
    Environment = var.environment
    ManagedBy   = "env0"
    Demo        = "pr-label-approval-policy"
  }
}
