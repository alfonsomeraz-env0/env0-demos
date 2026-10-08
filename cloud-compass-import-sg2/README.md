# cloud-compass-import-sg2

Imports the ClickOps-created security group `vpce-sg2` into Terraform. It lives in the manually created VPC `vpce-demo-vpc2` (10.50.0.0/16), which is referenced through a data source and not managed. The endpoint `test-vpce2` is left untracked.

## env0 setup

- Template type: Terraform 1.5.7, path `cloud-compass-import-sg2`
- Project: Dev - ADM
