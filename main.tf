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
  source                     = "./modules/kubernetes"
  cluster_count              = 1
  deletion_protection        = var.deletion_protection
  project_id                 = var.project_id
  region                     = var.region
  network_name               = module.network.network_name
  subnetwork_name            = module.network.subnetwork_name
  pods_range_name            = module.network.pods_range_name
  services_range_name        = module.network.services_range_name
  node_service_account_email = module.node_service_account.service_account_mail
  security_group             = var.security_group

  depends_on = [module.node_service_account, module.artifact_registry, module.network]
}

module "service_account" {
  source                      = "./modules/service_account"
  project_id                  = var.project_id
  service_account_id          = "kubernetes-sa"
  service_account_description = "Read-only Kubernetes automation identity"
  service_account_roles       = ["roles/container.viewer"]

  depends_on = [module.necessary_api]
}

module "node_service_account" {
  source                      = "./modules/service_account"
  project_id                  = var.project_id
  service_account_id          = "gke-nodes"
  service_account_description = "GKE node system identity"
  service_account_roles       = ["roles/container.defaultNodeServiceAccount"]
  depends_on                  = [module.necessary_api]
}

module "artifact_registry" {
  source                     = "./modules/artifact_registry"
  project_id                 = var.project_id
  region                     = var.region
  node_service_account_email = module.node_service_account.service_account_mail
  depends_on                 = [module.necessary_api]
}

module "operations" {
  source          = "./modules/operations"
  project_id      = var.project_id
  billing_account = var.billing_account
  monthly_budget  = var.monthly_budget
  budget_currency = var.budget_currency
  alert_email     = var.alert_email
  cluster_name    = module.kubernetes.cluster_names[0]
  region          = var.region
  depends_on      = [module.necessary_api]
}

# Cluster discovery/connect only. Namespace permissions are granted using RBAC.
resource "google_project_iam_member" "cluster_operators" {
  for_each   = var.cluster_operator_members
  project    = var.project_id
  role       = "roles/container.clusterViewer"
  member     = each.value
  depends_on = [module.necessary_api]
}

module "workload_identity" {
  for_each                   = var.workload_identities
  source                     = "./modules/workload_identity"
  project_id                 = var.project_id
  account_id                 = each.value.account_id
  namespace                  = each.value.namespace
  kubernetes_service_account = each.value.kubernetes_service_account
  depends_on                 = [module.necessary_api, module.kubernetes]
}
