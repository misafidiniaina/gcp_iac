output "enabled_services" {
  description = "List of enabled services"
  value = [
    google_project_service.compute_api.service,
    google_project_service.iam_api.service,
    google_project_service.container_api.service,
    google_project_service.cloudresourcemanager_api.service,
    google_project_service.serviceusage_api.service,
    google_project_service.artifact_registry_api.service
  ]
}
