variable "project_id" {
  description = "Google Cloud project ID."
  type        = string
}

variable "region" {
  description = "GKE region."
  type        = string
}

variable "cluster_name" {
  description = "Cluster monitored for container restarts."
  type        = string
}

variable "billing_account" {
  description = "Billing account ID."
  type        = string
}

variable "monthly_budget" {
  description = "Monthly whole currency units; alert threshold, not a cap."
  type        = number
}

variable "budget_currency" {
  description = "Billing account currency."
  type        = string
}

variable "alert_email" {
  description = "Monitored operations email address."
  type        = string
}
