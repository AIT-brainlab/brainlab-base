# Management Plane Cost Safeguards & Monitoring

# Notification Channel: Lead Admin Email
resource "google_monitoring_notification_channel" "admin_email" {
  display_name = "AIT Brainlab Management Admin"
  type         = "email"
  labels = {
    email_address = var.alert_email
  }

  depends_on = [google_project_service.mgmt_services]
}

# Notification Channel: Secondary Backup Email
resource "google_monitoring_notification_channel" "backup_email" {
  display_name = "Akraradet Personal Billing Backup"
  type         = "email"
  labels = {
    email_address = "akraradets@gmail.com"
  }

  depends_on = [google_project_service.mgmt_services]
}
