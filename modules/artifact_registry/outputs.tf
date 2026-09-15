output "repository_url" {
  description = "Docker repository URL for image push/pull."
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.images.repository_id}"
}
