resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  bucket_name         = var.bucket_name != "" ? var.bucket_name : "demo-env0-terragrunt-state-${random_id.suffix.hex}"
  dynamodb_table_name = var.dynamodb_table_name != "" ? var.dynamodb_table_name : "demo-env0-terragrunt-lock-${random_id.suffix.hex}"
}

resource "aws_s3_bucket" "tfstate" {
  bucket = local.bucket_name

  tags = {
    Name      = local.bucket_name
    ManagedBy = "terraform"
    Purpose   = "terragrunt-remote-state"
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "tfstate_lock" {
  name         = local.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name      = local.dynamodb_table_name
    ManagedBy = "terraform"
    Purpose   = "terragrunt-state-lock"
  }
}
