resource "google_compute_instance" "vm-server" {
  project      = var.project_id
  name         = "vm-server"
  machine_type = "e2-medium"
  zone         = var.zone
  tags         = ["vm-server"]
  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts"
      size  = 20
    }
  }
  network_interface {
    network    = var.network_name
    subnetwork = var.subnetwork_name
    access_config {}
  }

  metadata = {
    enable-oslogin = "TRUE"
  }
}
