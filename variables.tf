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

variable "billing_account" {
  description = "Billing account ID used for the project-scoped budget."
  type        = string
  validation {
    condition     = can(regex("^[A-Fa-f0-9]{6}-[A-Fa-f0-9]{6}-[A-Fa-f0-9]{6}$", var.billing_account))
    error_message = "Use a billing account ID such as 012345-ABCDEF-012345."
  }
}

variable "monthly_budget" {
  description = "Monthly project budget in whole currency units; notifications only, not a spending cap."
  type        = number
  validation {
    condition     = var.monthly_budget > 0 && floor(var.monthly_budget) == var.monthly_budget
    error_message = "monthly_budget must be a positive whole number."
  }
}

variable "budget_currency" {
  description = "ISO currency code matching the billing account currency."
  type        = string
  default     = "USD"
  validation {
    condition     = can(regex("^[A-Z]{3}$", var.budget_currency))
    error_message = "Use a three-letter uppercase currency code."
  }
}

variable "alert_email" {
  description = "Monitored email address for infrastructure and budget alerts."
  type        = string
  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.alert_email))
    error_message = "Provide a valid alert email address."
  }
}

variable "cluster_operator_members" {
  description = "IAM users/groups allowed to discover and connect to GKE; grant workload access separately with RBAC."
  type        = set(string)
  default     = []
  validation {
    condition     = alltrue([for member in var.cluster_operator_members : can(regex("^(user|group|serviceAccount):[^ ]+@[^ ]+$", member))])
    error_message = "Use explicit user:, group:, or serviceAccount: IAM members."
  }
}

variable "security_group" {
  description = "Optional Google Groups for RBAC parent group."
  type        = string
  default     = null
}

variable "workload_identities" {
  description = "Keyless workload identities; grant resource-specific permissions separately."
  type = map(object({
    account_id                 = string
    namespace                  = string
    kubernetes_service_account = string
  }))
  default = {}
  validation {
    condition = alltrue([for identity in values(var.workload_identities) :
      can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", identity.account_id)) &&
      can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", identity.namespace)) &&
      length(identity.namespace) <= 63 &&
      can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", identity.kubernetes_service_account)) &&
      length(identity.kubernetes_service_account) <= 63
    ])
    error_message = "Use valid Google service account IDs and Kubernetes namespace/service account names (no wildcards)."
  }
}
