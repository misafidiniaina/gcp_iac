output "bucket_name" {
  description = "Use as bucket in the root backend.hcl."
  value       = google_storage_bucket.state.name
}
