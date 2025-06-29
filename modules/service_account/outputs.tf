output "service_account_key" {
  description = "The private key of the service account in JSON format."
  value = base64decode(google_service_account_key.service_account_key.private_key)
}
output "service_account_mail" {
  description = "corresponding address for the service account"
  value = google_service_account.service_account.email
}