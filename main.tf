provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

module "necessary_api" {
  source     = "./modules/necessary_api"
  project_id = var.project_id
}

module "network" {
  source     = "./modules/network"
  project_id = var.project_id
  region     = var.region

  depends_on = [module.necessary_api]
}

module "kubernetes" {
  source          = "./modules/kubernetes"
  cluster_count   = 1
  project_id      = var.project_id
  region          = var.region
  network_name    = module.network.network_name
  subnetwork_name = module.network.subnetwork_name
}

module "service_account" {
  source                      = "./modules/service_account"
  project_id                  = var.project_id
  service_account_id          = "kubernetes-sa"
  service_account_description = "Read-only Kubernetes automation identity"
  service_account_roles       = ["roles/container.viewer"]

  depends_on = [module.necessary_api]
}
