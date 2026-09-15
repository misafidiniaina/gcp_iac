output "cluster_names" {
  description = "Names of the regional Autopilot clusters."
  value       = google_container_cluster.autopilot_cluster[*].name
}
