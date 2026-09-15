variable "network_name" {
  description = "VPC network name."
  type        = string
}

variable "subnetwork_name" {
  description = "Regional subnetwork name."
  type        = string
}

variable "region" {
  description = "Google Cloud region."
  type        = string
}

variable "project_id" {
  description = "Google Cloud project ID."
  type        = string
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

variable "pods_range_name" {
  description = "Existing subnet secondary range for Pods."
  type        = string
}

variable "services_range_name" {
  description = "Existing subnet secondary range for Services."
  type        = string
}

variable "node_service_account_email" {
  description = "Dedicated node identity with GKE node permissions."
  type        = string
}

variable "security_group" {
  description = "Optional Google Groups for RBAC parent group, gke-security-groups@your-domain."
  type        = string
  default     = null
}
