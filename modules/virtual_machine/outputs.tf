output "instance_name" {
  description = "Instance name for gcloud compute ssh with IAP."
  value       = google_compute_instance.vm-server.name
}
