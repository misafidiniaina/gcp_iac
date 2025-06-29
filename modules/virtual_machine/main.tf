resource "google_compute_instance" "vm-server" {
  name         = "vm-server"
  machine_type = "e2-medium"
  zone         = var.zone
  tags = ["vm-server"]
  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2204-jammy-v20241119"
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

//to get user information
data "google_client_openid_userinfo" "me" {
}

//adding key for ssh connection
resource "google_os_login_ssh_public_key" "add_my_key" {
  project = var.project_id
  user =  data.google_client_openid_userinfo.me.email
  key = file("~/.ssh/id_ed25519.pub")
}
output "vm_server_url" {
  value = "http://${google_compute_instance.vm-server.network_interface.0.access_config.0.nat_ip}:8080"
}
