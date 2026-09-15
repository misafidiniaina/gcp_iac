mock_provider "google" {}

run "root_composition" {
  command = plan
  variables {
    project_id      = "production-test"
    billing_account = "012345-ABCDEF-012345"
    monthly_budget  = 100
    alert_email     = "operations@example.com"
  }
  assert {
    condition     = output.cluster_names == ["kubernetescluster"]
    error_message = "The production root must deploy one cluster."
  }
  assert {
    condition     = output.artifact_registry_url == "us-central1-docker.pkg.dev/production-test/applications"
    error_message = "Images must stay in the cluster region/project."
  }
}

run "private_cluster" {
  command = plan
  module {
    source = "./modules/kubernetes"
  }
  variables {
    project_id                 = "production-test"
    region                     = "us-central1"
    cluster_count              = 1
    network_name               = "test-network"
    subnetwork_name            = "test-subnet"
    pods_range_name            = "gke-pods"
    services_range_name        = "gke-services"
    node_service_account_email = "gke-nodes@production-test.iam.gserviceaccount.com"
  }
  assert {
    condition = (
      google_container_cluster.autopilot_cluster[0].private_cluster_config[0].enable_private_nodes &&
      google_container_cluster.autopilot_cluster[0].private_cluster_config[0].enable_private_endpoint &&
      google_container_cluster.autopilot_cluster[0].deletion_protection
    )
    error_message = "Nodes and the IP endpoint must be private, with deletion protection enabled."
  }
  assert {
    condition = (
      google_container_cluster.autopilot_cluster[0].node_config[0].service_account == var.node_service_account_email &&
      google_container_cluster.autopilot_cluster[0].ip_allocation_policy[0].cluster_secondary_range_name == "gke-pods" &&
      google_container_cluster.autopilot_cluster[0].control_plane_endpoints_config[0].dns_endpoint_config[0].allow_external_traffic
    )
    error_message = "GKE must use its dedicated identity, planned Pod range, and IAM-authenticated DNS access."
  }
}

run "private_network_egress" {
  command = plan
  module {
    source = "./modules/network"
  }
  variables {
    project_id = "production-test"
    region     = "us-central1"
  }
  assert {
    condition = (
      google_compute_subnetwork.subnetwork.private_ip_google_access &&
      length(google_compute_subnetwork.subnetwork.secondary_ip_range) == 2 &&
      google_compute_router_nat.nat.source_subnetwork_ip_ranges_to_nat == "LIST_OF_SUBNETWORKS"
    )
    error_message = "Private nodes need Google API access, dedicated Pod/Service ranges, and subnet-scoped NAT."
  }
  assert {
    condition = (
      google_compute_firewall.firewall.source_ranges == toset(["35.235.240.0/20"]) &&
      one(google_compute_firewall.firewall.allow).ports == tolist(["22"])
    )
    error_message = "SSH ingress must remain restricted to IAP on port 22."
  }
}

run "budget_and_alerts" {
  command = plan
  module {
    source = "./modules/operations"
  }
  variables {
    project_id      = "production-test"
    region          = "us-central1"
    cluster_name    = "kubernetescluster"
    billing_account = "012345-ABCDEF-012345"
    monthly_budget  = 100
    budget_currency = "USD"
    alert_email     = "operations@example.com"
  }
  override_data {
    target = data.google_project.current
    values = { number = "123456789012" }
  }
  assert {
    condition = (
      google_billing_budget.project.budget_filter[0].projects == toset(["projects/123456789012"]) &&
      length(google_billing_budget.project.threshold_rules) == 4 &&
      length(google_monitoring_alert_policy.restarts.notification_channels) == 1
    )
    error_message = "Budget must cover only this project, with actual/forecast thresholds and routed restart alerts."
  }
}

run "reject_invalid_budget" {
  command = plan
  variables {
    project_id      = "production-test"
    billing_account = "012345-ABCDEF-012345"
    monthly_budget  = -1
    alert_email     = "operations@example.com"
  }
  expect_failures = [var.monthly_budget]
}

run "workload_identity_scope" {
  command = plan
  module {
    source = "./modules/workload_identity"
  }
  variables {
    project_id                 = "production-test"
    account_id                 = "orders-app"
    namespace                  = "orders"
    kubernetes_service_account = "api"
  }
  assert {
    condition = (
      google_service_account_iam_member.workload.role == "roles/iam.workloadIdentityUser" &&
      google_service_account_iam_member.workload.member == "serviceAccount:production-test.svc.id.goog[orders/api]"
    )
    error_message = "Workload impersonation must be restricted to the exact namespace/service account."
  }
}
