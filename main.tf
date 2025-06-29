provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}
 
 // activate necessary api for the project (compute, iam, container, cloudresourcemanager, serviceusage, google artifact for docker registry ...)
module "necessary_api" {
  source     = "./modules/necessary_api"
  project_id = var.project_id
}

// Create the VPC for the infrastructure
module "network" {
  source      = "./modules/network"
  project_id  = var.project_id
  region      = var.region
}


// provision gce as Jenkins Standalone (and Bastion Host server) server
# module "virtual_machine" {
#   source          = "./modules/virtual_machine"
#   project_id      = var.project_id
#   network_name    = module.network.network_name
#   subnetwork_name = module.network.subnetwork_name
#   region          = var.region
#   zone            = var.zone
#   depends_on = [ module.network ]
# }

// create gke 
module "kubernetes" {
  source = "./modules/kubernetes"
  cluster_count = 1
  project_id = var.project_id
  region = var.region
  network_name = module.network.network_name
  subnetwork_name = module.network.subnetwork_name
  depends_on = [ module.network ]
}

// get service_account, with necessary role to interact with the kubernetes cluster
module "service_account" {
  source = "./modules/service_account"
  region                     = var.region
  project_id                 = var.project_id
  service_account_id         = "kubernetes-sa"
  service_account_description = "Service account to interact with the kubernetes"
  service_account_roles      = [
    "roles/container.admin",
    "roles/storage.admin",
    "roles/iam.serviceAccountUser"
  ]
}


# module "artifact_registry" {
#   source    = "./modules/artifact_registry"
#   project_id = var.project_id
#   region     = var.region
#   repo_name  = "haog-target-repo"
#   environment = "production"
#   gke_sa_email_k8s1 = module.kubernetes.gke_sa_email_k8s2
#   gke_sa_email_k8s2 = module.kubernetes.gke_sa_email_k8s2
# }



