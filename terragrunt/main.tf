module "s3" {
  source = "./s3"

  environment               = "dev"
  bucket_name               = "demo-env0-dev-alfonso"
  version_retention_days    = 30
  enable_lifecycle_archival = false
  archive_transition_days   = 90
}

module "vpc" {
  source = "./vpc"

  environment        = "dev"
  vpc_cidr           = "10.0.0.0/16"
  public_subnet_cidr = "10.0.1.0/24"
  availability_zone  = "us-east-2a"
}

module "iam" {
  source = "./iam"

  environment    = "dev"
  s3_bucket_name = module.s3.bucket_id
}

module "security_groups" {
  source = "./security_groups"

  environment       = "dev"
  vpc_id            = module.vpc.vpc_id
  allowed_ssh_cidrs = ["0.0.0.0/0"]
}

module "ec2" {
  source = "./ec2"

  environment               = "dev"
  instance_name             = "demo-env0"
  instance_type             = "t2.micro"
  subnet_id                 = module.vpc.public_subnet_id
  security_group_ids        = [module.security_groups.ec2_security_group_id]
  iam_instance_profile_name = module.iam.ec2_instance_profile_name
  root_volume_size          = 20
}
