output "service_account_email" {
  description = "Automation identity for impersonation or Workload Identity Federation."
  value       = module.service_account.service_account_mail
}

output "activate_api" {
  description = "Google Cloud APIs managed by this configuration."
  value       = module.necessary_api.enabled_services
}
