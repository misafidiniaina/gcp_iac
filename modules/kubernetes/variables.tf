variable "network_name" {
  type = string
}

variable "subnetwork_name" {
  type = string
}

variable "region" {
  type = string
}

variable "project_id" {
  type = string
}


variable "cluster_count" {
  description = "Number of clusters; existing naming supports one primary and one test cluster."
  type        = number
  validation {
    condition     = contains([1, 2], var.cluster_count)
    error_message = "cluster_count must be 1 or 2."
  }
}

variable "deletion_protection" {
  description = "Protect clusters from accidental Terraform deletion."
  type        = bool
  default     = true
}