resource "aws_s3_bucket" "tfstate" {
  bucket = var.state_bucket_name

  tags = {
    Name      = var.state_bucket_name
    ManagedBy = "terraform"
    Purpose   = "terraform-remote-state"
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

# The lock table needs exactly one attribute: a string partition key called
# LockID. HashiCorp deprecated DynamoDB-based locking in favor of S3
# lockfiles (use_lockfile = true) on Terraform/OpenTofu 1.10+ with AWS
# provider v5+ — set use_dynamodb_locking = false to skip this resource.
resource "aws_dynamodb_table" "tfstate_lock" {
  count        = var.use_dynamodb_locking ? 1 : 0
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name      = var.dynamodb_table_name
    ManagedBy = "terraform"
    Purpose   = "terraform-state-lock"
  }
}
