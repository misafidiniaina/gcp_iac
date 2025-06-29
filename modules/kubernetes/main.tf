resource "google_container_cluster" "autopilot_cluster" {
  count    = var.cluster_count  
  name     = "kubernetescluster${count.index == 0 ? "" : "-test"}"  
  location = var.region             

  enable_autopilot = true

  network    = var.network_name
  subnetwork = var.subnetwork_name
  deletion_protection   = false 

  ip_allocation_policy {}
  
}
