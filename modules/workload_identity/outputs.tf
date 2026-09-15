output "email" {
  description = "Use in the Kubernetes service account iam.gke.io/gcp-service-account annotation."
  value       = google_service_account.workload.email
}
