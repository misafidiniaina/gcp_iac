resource "google_compute_network" "vpc_network" {
  project                 = var.project_id
  name                    = "infrastructure-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnetwork" {
  project                  = var.project_id
  name                     = "subnet"
  region                   = var.region
  network                  = google_compute_network.vpc_network.id
  ip_cidr_range            = var.subnet_cidr
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "gke-pods"
    ip_cidr_range = var.pods_cidr
  }
  secondary_ip_range {
    range_name    = "gke-services"
    ip_cidr_range = var.services_cidr
  }
  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.1
    metadata             = "EXCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "firewall" {
  project     = var.project_id
  name        = "allow-some-port"
  description = "Allow SSH through Identity-Aware Proxy to tagged VMs."
  network     = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags   = ["vm-server"]
  source_ranges = ["35.235.240.0/20"]
}

# Private nodes use NAT for external registries and other internet dependencies.
resource "google_compute_router" "router" {
  project = var.project_id
  name    = "gke-router"
  region  = var.region
  network = google_compute_network.vpc_network.id
}

resource "google_compute_router_nat" "nat" {
  project                            = var.project_id
  name                               = "gke-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.subnetwork.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
