variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "VPC that will hold the security group"
  type        = string
}

variable "name" {
  description = "Security group name"
  type        = string
  default     = "vpce-sg"
}

variable "description" {
  description = "Security group description"
  type        = string
  default     = "vpce-sg"
}

variable "ingress_rules" {
  description = "Inbound rules. Outbound is left empty."
  type = list(object({
    description = optional(string)
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/24"]
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["20.0.0.0/24"]
    },
  ]
}

variable "tags" {
  description = "Extra tags; Name is always set from var.name"
  type        = map(string)
  default     = {}
}
