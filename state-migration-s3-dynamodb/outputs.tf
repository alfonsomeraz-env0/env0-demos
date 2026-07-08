locals {
  backend_snippet_dynamodb = <<-EOT
    terraform {
      backend "s3" {
        bucket         = "${aws_s3_bucket.tfstate.id}"
        key            = "<environment-name>/terraform.tfstate"
        region         = "${var.aws_region}"
        dynamodb_table = "${one(aws_dynamodb_table.tfstate_lock[*].name)}"
        encrypt        = true
      }
    }
  EOT

  backend_snippet_lockfile = <<-EOT
    terraform {
      backend "s3" {
        bucket       = "${aws_s3_bucket.tfstate.id}"
        key          = "<environment-name>/terraform.tfstate"
        region       = "${var.aws_region}"
        use_lockfile = true
        encrypt      = true
      }
    }
  EOT
}

output "bucket_name" {
  value = aws_s3_bucket.tfstate.id
}

output "dynamodb_table_name" {
  value = one(aws_dynamodb_table.tfstate_lock[*].name)
}

output "aws_region" {
  value = var.aws_region
}

output "backend_config_snippet" {
  description = "Paste this into each environment you're migrating off the env0 remote backend"
  value       = var.use_dynamodb_locking ? local.backend_snippet_dynamodb : local.backend_snippet_lockfile
}
