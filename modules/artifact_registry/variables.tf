variable "project_id" {
  description = "Google Cloud project ID."
  type        = string
}

variable "region" {
  description = "Repository region, colocated with GKE."
  type        = string
}

variable "node_service_account_email" {
  description = "Node identity permitted to pull images from this repository only."
  type        = string
}
