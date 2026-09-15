variable "project_id" {
  description = "GKE project ID and Workload Identity pool project."
  type        = string
}

variable "account_id" {
  description = "Google service account ID for the workload."
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace authorized to impersonate this identity."
  type        = string
}

variable "kubernetes_service_account" {
  description = "Exact Kubernetes service account authorized to impersonate this identity."
  type        = string
}
