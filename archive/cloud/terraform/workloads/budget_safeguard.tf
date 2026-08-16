# Research Budget Alert Notification Channel & Pub/Sub Topic

resource "google_pubsub_topic" "budget_notifications" {
  name = "budget-alert-topic"
}

# Monitoring Alert Notification Email Channel
resource "google_monitoring_notification_channel" "email_alert" {
  display_name = "Brainlab Lead Admin Alert"
  type         = "email"
  labels = {
    email_address = var.alert_email
  }
}
