// Allows enabling and disabling services within your Google Cloud project.
resource "google_project_service" "serviceusage_api" {
  project = var.project_id
  service = "serviceusage.googleapis.com"
}

//Needed for managing service accounts, roles, and permissions.
resource "google_project_service" "iam_api" {
  project = var.project_id
  service = "iam.googleapis.com"
}

// Needed for creating VPCs, subnets, and Compute Engine (VM instances, load balancers, etc.).
resource "google_project_service" "compute_api" {
  project = var.project_id
  service = "compute.googleapis.com"
}


// Required for creating and managing Kubernetes Engine (GKE) clusters.
resource "google_project_service" "container_api" {
  project = var.project_id
  service = "container.googleapis.com"
}

// Needed for managing projects and getting project details like organization policies.
resource "google_project_service" "cloudresourcemanager_api" {
  project = var.project_id
  service = "cloudresourcemanager.googleapis.com"
}


// Required for managing and storing container images and other artifacts.
resource "google_project_service" "artifact_registry_api" {
  project = var.project_id
  service = "artifactregistry.googleapis.com"
}

