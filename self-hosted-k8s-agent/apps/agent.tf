resource "kubernetes_namespace" "agent" {
  metadata {
    name = var.agent_namespace
  }
}

# Resolved by the AWS provider at apply time - the plaintext token is marked
# sensitive by the provider and never appears in plan/apply output or logs.
data "aws_secretsmanager_secret_version" "agent_token" {
  secret_id = var.agent_token_secret_id
}

resource "helm_release" "env0_agent" {
  name       = var.agent_release_name
  repository = var.agent_chart_repository
  chart      = "env0-agent"
  version    = var.agent_chart_version
  namespace  = kubernetes_namespace.agent.metadata[0].name

  set_sensitive {
    name  = "agentAccessToken"
    value = data.aws_secretsmanager_secret_version.agent_token.secret_string
  }
}
