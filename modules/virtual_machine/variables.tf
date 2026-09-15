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

variable "zone" {
  description = "Google Cloud zone."
  type        = string
}

variable "project_id" {
  description = "Google Cloud project ID."
  type        = string
}
