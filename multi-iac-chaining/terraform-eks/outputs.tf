output "cluster_name" {
  description = "EKS cluster name — used by downstream Helm/Ansible environments"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded CA certificate for the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_oidc_issuer_url" {
  description = "OIDC provider URL for IAM Roles for Service Accounts (IRSA)"
  value       = module.eks.cluster_oidc_issuer_url
}

output "region" {
  description = "AWS region the cluster was deployed to"
  value       = var.region
}

output "vpc_id" {
  description = "VPC ID hosting the EKS cluster"
  value       = module.vpc.vpc_id
}
