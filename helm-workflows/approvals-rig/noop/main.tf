terraform {
  required_version = ">= 1.4"
}

resource "terraform_data" "noop" {
  triggers_replace = timestamp() # non-empty plan every run, so every run asks for approval
}
