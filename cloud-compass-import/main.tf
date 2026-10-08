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

# Adopt the existing ClickOps-created resources into state
import {
  to = aws_security_group.vpce_sg
  id = "sg-0aef10234f2b580b7"
}

import {
  to = aws_vpc_endpoint.test_vpce1
  id = "vpce-0b61a89efc3e50614"
}

resource "aws_security_group" "vpce_sg" {
  name        = "vpce-sg"
  description = "vpce-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/24"]
  }

  tags = {
    Name = "vpce-sg"
  }
}

resource "aws_vpc_endpoint" "test_vpce1" {
  vpc_id              = var.vpc_id
  service_name        = var.endpoint_service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.subnet_id]
  security_group_ids  = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "test-vpce1"
  }
}
