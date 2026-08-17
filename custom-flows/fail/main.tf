terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  # VIOLATION: Hardcoded credentials
  access_key = "AKIAIOSFODNN7EXAMPLE"
  secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
}

# VIOLATION: No encryption
resource "aws_s3_bucket" "insecure_bucket" {
  bucket = "my-insecure-bucket"
  
  # VIOLATION: Public ACL
  acl = "private"

  tags = {
    Name = "InsecureBucket"
  }
}

# VIOLATION: Security group with overly permissive rules
resource "aws_security_group" "insecure_sg" {
  name        = "insecure-sg"
  description = "Insecure security group for testing"
  
  # VIOLATION: Open to the world on all ports
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all traffic"
  }

  # VIOLATION: SSH open to the world
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# VIOLATION: RDS instance without encryption
resource "aws_db_instance" "insecure_db" {
  identifier           = "insecure-db"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  username             = "admin"
  password             = "password123"  # VIOLATION: Hardcoded password
  skip_final_snapshot  = true
  publicly_accessible  = true  # VIOLATION: Publicly accessible
  storage_encrypted    = false # VIOLATION: No encryption
  
  # VIOLATION: No backup retention
  backup_retention_period = 0
}

# VIOLATION: IAM policy too permissive
resource "aws_iam_policy" "admin_policy" {
  name        = "admin-policy"
  description = "Admin policy with full access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "*"  # VIOLATION: Wildcard permissions
        Resource = "*"
      }
    ]
  })
}