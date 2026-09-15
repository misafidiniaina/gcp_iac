variable "project_id" {
  description = "Google Cloud project ID."
  type        = string
}

variable "service_account_id" {
  description = "Service account ID, unique within the project."
  type        = string
}

variable "service_account_description" {
  description = "Display name for the automation identity."
  type        = string
}

variable "service_account_roles" {
  type = list(string)
  default = [
    "roles/container.viewer"
  ]
  description = "Project IAM roles granted to the automation identity."
}
