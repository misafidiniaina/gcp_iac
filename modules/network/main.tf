resource "google_compute_network" "vpc_network" {
  name = "infrastructure-vpc"
}

resource "google_compute_subnetwork" "subnetwork" {
  name          = "subnet"
  region        = var.region
  network       = google_compute_network.vpc_network.id
  ip_cidr_range = "10.0.0.0/24"
}

resource "google_compute_firewall" "firewall" {
  name    = "allow-some-port"
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = ["22", "8080", "50000", "3000", "9090", "9100", "9093", "8443"]
  }

  target_tags = ["vm-server"]
  source_ranges = ["0.0.0.0/0"]
}
