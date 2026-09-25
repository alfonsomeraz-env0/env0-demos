variable "eks_cluster_name" {
  description = "EKS cluster name - output from the infra stage"
  type        = string
  default     = "env0-self-hosted-agent-eks"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "agent_namespace" {
  description = "Kubernetes namespace for the env0 self-hosted agent"
  type        = string
  default     = "env0-agent"
}

variable "agent_release_name" {
  description = "Helm release name"
  type        = string
  default     = "env0-agent"
}

variable "agent_chart_repository" {
  description = "Helm chart repository for env0-agent - get the exact URL from the env0 UI (Settings > Agents > self-hosted agent setup), it is not guessed here"
  type        = string
}

variable "agent_chart_version" {
  description = "env0-agent chart version to pin (leave null to use the repository default, not recommended for production)"
  type        = string
  default     = null
}

variable "agent_token_secret_id" {
  description = "AWS Secrets Manager secret id/ARN holding the env0 agent access token. Create this secret yourself, outside of any AI-assisted session, after rotating the token in env0."
  type        = string
  default     = "env0/self-hosted-agent/access-token"
}
