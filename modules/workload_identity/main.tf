resource "google_service_account" "workload" {
  project      = var.project_id
  account_id   = var.account_id
  display_name = "Workload ${var.namespace}/${var.kubernetes_service_account}"
}

resource "google_service_account_iam_member" "workload" {
  service_account_id = google_service_account.workload.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.namespace}/${var.kubernetes_service_account}]"
}
