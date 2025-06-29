resource "google_service_account" "service_account" {
  account_id   = var.service_account_id
  display_name = var.service_account_description
}

resource "google_project_iam_member" "service_account_roles" {
  for_each = toset(var.service_account_roles)
  project = var.project_id
  member  = "serviceAccount:${google_service_account.service_account.email}"
  role    = each.key
}

resource "google_service_account_key" "service_account_key" {
  service_account_id = google_service_account.service_account.name
  private_key_type   = "TYPE_GOOGLE_CREDENTIALS_FILE" //this line is optional cause (default value)
  depends_on         = [google_project_iam_member.service_account_roles]
}
