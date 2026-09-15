resource "google_artifact_registry_repository" "images" {
  project       = var.project_id
  location      = var.region
  repository_id = "applications"
  description   = "Production application images"
  format        = "DOCKER"

  docker_config {
    immutable_tags = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_artifact_registry_repository_iam_member" "node_reader" {
  project    = var.project_id
  location   = google_artifact_registry_repository.images.location
  repository = google_artifact_registry_repository.images.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${var.node_service_account_email}"
}
