module "remote_state_bucket" {
  source = "github.com/env0/remote-state-bucket-module//aws"

  external_id       = var.external_id
  state_bucket_name = var.state_bucket_name
  region            = var.aws_region
}
