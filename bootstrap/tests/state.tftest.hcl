mock_provider "google" {}

variables {
  project_id    = "production-test"
  bucket_name   = "production-test-terraform-state"
  state_members = ["user:operator@example.com"]
}

run "protected_state" {
  command = plan
  assert {
    condition = (
      google_storage_bucket.state.versioning[0].enabled &&
      google_storage_bucket.state.uniform_bucket_level_access &&
      google_storage_bucket.state.public_access_prevention == "enforced" &&
      !google_storage_bucket.state.force_destroy
    )
    error_message = "State must be versioned, private, and protected against forced deletion."
  }
}

run "reject_public_state_access" {
  command = plan
  variables {
    state_members = ["allUsers"]
  }
  expect_failures = [var.state_members]
}
