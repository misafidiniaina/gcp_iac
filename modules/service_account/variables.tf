variable "project_id" {
  type = string
}

variable "service_account_id" {
  type = string
}

variable "service_account_description" {
  type = string
}

variable "service_account_roles" {
  type = list(string)
  default = [
    "roles/container.viewer"
  ]
  description = "Project IAM roles granted to the automation identity."
}
