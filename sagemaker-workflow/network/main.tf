terraform {
  # Runs on OpenTofu 1.6+ or Terraform 1.2+ — env0's default Terraform is 1.5.7.
  required_version = ">= 1.2.0"

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
    tags = {
      Environment = var.environment
      ManagedBy   = "OpenTofu"
      Demo        = "sagemaker-workflow"
      Stage       = "network"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.environment}-sagemaker-vpc" }
}

resource "aws_subnet" "notebook" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = { Name = "${var.environment}-sagemaker-subnet" }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = { Name = "${var.environment}-sagemaker-igw" }
}

resource "aws_route_table" "notebook" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = { Name = "${var.environment}-sagemaker-rt" }
}

resource "aws_route_table_association" "notebook" {
  subnet_id      = aws_subnet.notebook.id
  route_table_id = aws_route_table.notebook.id
}

# The notebook ENI needs egress (pip, S3, SageMaker APIs) but never inbound —
# Jupyter is reached through a presigned SageMaker URL, not this network.
resource "aws_security_group" "notebook" {
  name        = "${var.environment}-sagemaker-notebook"
  description = "Egress-only security group for the SageMaker notebook ENI"
  vpc_id      = aws_vpc.this.id

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.environment}-sagemaker-notebook-sg" }
}
