terraform {
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

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_subnet" "selected" {
  id = var.subnet_id
}

data "aws_security_groups" "default" {
  filter {
    name   = "group-name"
    values = ["default"]
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_subnet.selected.vpc_id]
  }
}

locals {
  ami_root_size    = [for bdm in data.aws_ami.amazon_linux.block_device_mappings : bdm.ebs.volume_size if bdm.device_name == data.aws_ami.amazon_linux.root_device_name][0]
  root_volume_size = max(var.root_volume_size, local.ami_root_size)

  # AWS rejects an explicit empty security-group list on VPC instances ("at
  # least one security group required"), so fall back to the VPC's default
  # security group instead of passing an empty list through.
  explicit_security_group_ids = var.security_group_ids != "" ? jsondecode(var.security_group_ids) : []
  security_group_ids          = length(local.explicit_security_group_ids) > 0 ? local.explicit_security_group_ids : data.aws_security_groups.default.ids
}

resource "aws_instance" "this" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = local.security_group_ids

  root_block_device {
    volume_type           = "gp3"
    volume_size           = local.root_volume_size
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name        = "${var.environment}-root-volume"
      Environment = var.environment
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  monitoring = true

  tags = {
    Name        = "${var.environment}-${var.instance_name}"
    Environment = var.environment
  }
}
