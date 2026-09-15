variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}


variable "deletion_protection" {
  description = "Protect GKE from deletion; disable and apply before intentional teardown."
  type        = bool
  default     = true
}
