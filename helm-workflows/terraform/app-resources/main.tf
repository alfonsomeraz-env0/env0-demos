terraform {
  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 5.0" }
    random = { source = "hashicorp/random", version = "~> 3.0" }
  }
}

variable "region" {
  type    = string
  default = "us-east-2"
}

provider "aws" {
  region = var.region
}

resource "random_pet" "suffix" {}

resource "aws_s3_bucket" "app" {
  bucket        = "helm-demo-${random_pet.suffix.id}"
  force_destroy = true
}

output "bucket_name" {
  value = aws_s3_bucket.app.bucket
}
