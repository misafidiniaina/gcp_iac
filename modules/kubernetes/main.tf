resource "google_container_cluster" "autopilot_cluster" {
  project  = var.project_id
  count    = var.cluster_count
  name     = "kubernetescluster${count.index == 0 ? "" : "-test"}"
  location = var.region

  enable_autopilot = true

  network             = var.network_name
  subnetwork          = var.subnetwork_name
  deletion_protection = var.deletion_protection

  networking_mode = "VPC_NATIVE"

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
  }

  # Operators use the IAM-authenticated DNS endpoint, without a bastion or VPN.
  control_plane_endpoints_config {
    dns_endpoint_config {
      allow_external_traffic = true
    }
  }

  node_config {
    service_account = var.node_service_account_email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  release_channel {
    channel = "REGULAR"
  }

  maintenance_policy {
    recurring_window {
      start_time = "2026-01-01T00:00:00Z"
      end_time   = "2026-01-01T08:00:00Z"
      recurrence = "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU"
    }
  }

  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
    managed_prometheus {
      enabled = true
    }
  }

  dynamic "authenticator_groups_config" {
    for_each = var.security_group == null ? [] : [var.security_group]
    content {
      security_group = authenticator_groups_config.value
    }
  }

}
