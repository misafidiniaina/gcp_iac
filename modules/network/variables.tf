variable "region" {
  description = "Google Cloud region."
  type        = string
}

variable "project_id" {
  description = "Google Cloud project ID."
  type        = string
}

variable "subnet_cidr" {
  description = "Primary IPv4 subnet for nodes; must not overlap secondary or connected networks."
  type        = string
  default     = "10.0.0.0/24"
  validation {
    condition     = can(cidrnetmask(var.subnet_cidr))
    error_message = "subnet_cidr must be an IPv4 CIDR."
  }
}

variable "pods_cidr" {
  description = "Secondary IPv4 range for Pods; must not overlap other networks."
  type        = string
  default     = "10.4.0.0/14"
  validation {
    condition     = can(cidrnetmask(var.pods_cidr))
    error_message = "pods_cidr must be an IPv4 CIDR."
  }
}

variable "services_cidr" {
  description = "Secondary IPv4 range for Services; must not overlap other networks."
  type        = string
  default     = "10.8.0.0/20"
  validation {
    condition     = can(cidrnetmask(var.services_cidr))
    error_message = "services_cidr must be an IPv4 CIDR."
  }
}
