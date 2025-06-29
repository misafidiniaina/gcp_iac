variable "region" {
  type = string
}

variable "project_id" {
  type = string
}

variable "service_account_id"{
    type = string
}

variable "service_account_description"{
    type = string
}

variable "service_account_roles" {
  type    = list(string)
  default = [
    "roles/container.admin",
    "roles/storage.admin",
    "roles/iam.serviceAccountUser"
  ]
  description = "List of IAM roles to assign to the Jenkins service account."
}
