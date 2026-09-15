variable "project_id" {
  description = "Existing project for Terraform state storage."
  type        = string
}

variable "bucket_name" {
  description = "Globally unique Terraform state bucket name."
  type        = string
}

variable "region" {
  description = "State storage region."
  type        = string
  default     = "us-central1"
}

variable "state_members" {
  description = "Explicit deployment identities permitted to read/write state and locks."
  type        = set(string)
  validation {
    condition = length(var.state_members) > 0 && alltrue([
      for member in var.state_members : can(regex("^(user|group|serviceAccount):[^ ]+@[^ ]+$", member))
    ])
    error_message = "Specify at least one explicit IAM user, group, or service account; public members are prohibited."
  }
}
