output "service_account_mail" {
  description = "Email of the keyless automation service account."
  value       = google_service_account.service_account.email
}
