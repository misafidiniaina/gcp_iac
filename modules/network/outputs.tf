output "network_name" {
  description = "Name of the custom-mode VPC."
  value       = google_compute_network.vpc_network.name
}

output "subnetwork_name" {
  description = "Name of the regional subnet."
  value       = google_compute_subnetwork.subnetwork.name
}
