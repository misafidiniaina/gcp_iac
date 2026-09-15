resource "google_compute_network" "vpc_network" {
  project                 = var.project_id
  name                    = "infrastructure-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnetwork" {
  project       = var.project_id
  name          = "subnet"
  region        = var.region
  network       = google_compute_network.vpc_network.id
  ip_cidr_range = "10.0.0.0/24"
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
