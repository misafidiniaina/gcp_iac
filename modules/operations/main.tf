data "google_project" "current" {
  project_id = var.project_id
}

resource "google_monitoring_notification_channel" "email" {
  project      = var.project_id
  display_name = "Production operations"
  type         = "email"
  labels = {
    email_address = var.alert_email
  }
}

resource "google_monitoring_alert_policy" "restarts" {
  project               = var.project_id
  display_name          = "GKE repeated container restarts"
  combiner              = "OR"
  enabled               = true
  notification_channels = [google_monitoring_notification_channel.email.name]

  conditions {
    display_name = "More than 3 restarts in 5 minutes"
    condition_threshold {
      filter          = "resource.type = \"k8s_container\" AND resource.labels.cluster_name = \"${var.cluster_name}\" AND resource.labels.location = \"${var.region}\" AND metric.type = \"kubernetes.io/container/restart_count\""
      comparison      = "COMPARISON_GT"
      threshold_value = 3
      duration        = "0s"
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_DELTA"
      }
      trigger {
        count = 1
      }
    }
  }

  documentation {
    mime_type = "text/markdown"
    content   = "Check Pod events, previous container logs, resource limits and the latest rollout. Roll back the application release if necessary. See docs/production.md in the infrastructure repository."
  }
}

resource "google_billing_budget" "project" {
  billing_account = var.billing_account
  display_name    = "${var.project_id} monthly budget"

  budget_filter {
    projects        = ["projects/${data.google_project.current.number}"]
    calendar_period = "MONTH"
  }

  amount {
    specified_amount {
      currency_code = var.budget_currency
      units         = tostring(var.monthly_budget)
    }
  }

  dynamic "threshold_rules" {
    for_each = [0.5, 0.8, 1.0]
    content {
      threshold_percent = threshold_rules.value
      spend_basis       = "CURRENT_SPEND"
    }
  }

  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "FORECASTED_SPEND"
  }

  all_updates_rule {
    monitoring_notification_channels = [google_monitoring_notification_channel.email.name]
    disable_default_iam_recipients   = false
  }
}
