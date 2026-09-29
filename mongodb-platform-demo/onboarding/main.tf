terraform {
  required_version = ">= 1.0"

  required_providers {
    env0 = {
      source  = "env0/env0"
      version = "~> 1.0"
    }
  }
}

# Auth: set ENV0_API_KEY and ENV0_API_SECRET as environment variables on the
# env0 environment (mark the secret sensitive).
provider "env0" {}

variable "parent_project_id" {
  description = "Parent project that holds one sub-project per system"
  type        = string
}

variable "systems" {
  description = "One entry per system. Onboarding a system is a one-entry PR."
  type = map(object({
    description = string
  }))
  default = {
    "payments-ledger" = { description = "Payments ledger system" }
  }
}

resource "env0_project" "system" {
  for_each          = var.systems
  name              = each.key
  description       = each.value.description
  parent_project_id = var.parent_project_id
}

output "project_ids" {
  value = { for k, p in env0_project.system : k => p.id }
}
