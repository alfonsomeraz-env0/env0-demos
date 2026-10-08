terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# The manually created VPC is looked up, not managed
data "aws_vpc" "vpce_demo" {
  id = var.vpc_id
}

# Adopt the existing ClickOps-created security group into state
import {
  to = aws_security_group.vpce_sg2
  id = "sg-0fc9a229941e8d1fe"
}

resource "aws_security_group" "vpce_sg2" {
  name        = "vpce-sg2"
  description = "vpce-sg2"
  vpc_id      = data.aws_vpc.vpce_demo.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/24"]
  }

  tags = {
    Name = "vpce-sg2"
  }
}
