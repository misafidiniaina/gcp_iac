output "network_name" {
  description = "Name of the custom-mode VPC."
  value       = google_compute_network.vpc_network.name
}

output "subnetwork_name" {
  description = "Name of the regional subnet."
  value       = google_compute_subnetwork.subnetwork.name
}

output "pods_range_name" {
  description = "Secondary range reserved for GKE Pods."
  value       = google_compute_subnetwork.subnetwork.secondary_ip_range[0].range_name
}

output "services_range_name" {
  description = "Secondary range reserved for GKE Services."
  value       = google_compute_subnetwork.subnetwork.secondary_ip_range[1].range_name
}
