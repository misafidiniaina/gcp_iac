# output "vm_server_url" {
#   description = "The Jenkins instance URL"
#   value       = module.virtual_machine.vm_server_url
# }

output "kubernetes_sa_key" {
  description = "service account key for kubernetes interaction use it as ENV in Ansible or else"
  value = module.service_account.service_account_key
  sensitive = true
}

output "activate_api" {
  value = module.necessary_api.enabled_services
}