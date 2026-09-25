output "agent_namespace" {
  value = kubernetes_namespace.agent.metadata[0].name
}

output "agent_helm_release" {
  value = helm_release.env0_agent.name
}
