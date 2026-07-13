locals {
  aws_region  = "us-east-2"
  environment = "dev"
  project     = "demo-env0"
}

terraform {
  extra_arguments "migrate_state" {
    commands  = ["init"]
    arguments = ["-migrate-state", "-force-copy"]
  }
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "demo-env0-terragrunt-state"
    key            = "${local.environment}/terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    dynamodb_table = "demo-env0-terragrunt-lock"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"

  default_tags {
    tags = {
      Terraform   = "true"
      Environment = "${local.environment}"
      Project     = "${local.project}"
      ManagedBy   = "terragrunt"
    }
  }
}
EOF
}

generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
EOF
}
