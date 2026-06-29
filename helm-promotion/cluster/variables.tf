variable "region" {
  type    = string
  default = "us-east-2"
}

variable "cluster_name" {
  type    = string
  default = "helm-promotion"
}

variable "tags" {
  type    = map(string)
  default = {
    ManagedBy   = "env0"
    Environment = "demo"
  }
}
