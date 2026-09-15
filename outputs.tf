output "service_account_email" {
  description = "Automation identity for impersonation or Workload Identity Federation."
  value       = module.service_account.service_account_mail
}

output "activate_api" {
  description = "Google Cloud APIs managed by this configuration."
  value       = module.necessary_api.enabled_services
}

output "cluster_names" {
  description = "GKE cluster names for kubeconfig setup."
  value       = module.kubernetes.cluster_names
}

output "network_name" {
  description = "Custom-mode VPC name."
  value       = module.network.network_name
}

output "artifact_registry_url" {
  description = "Docker repository for production images."
  value       = module.artifact_registry.repository_url
}

output "node_service_account_email" {
  description = "Dedicated node identity; application permissions should use Workload Identity."
  value       = module.node_service_account.service_account_mail
}

output "workload_service_accounts" {
  description = "Workload identity emails keyed by workload name."
  value       = { for name, identity in module.workload_identity : name => identity.email }
}
