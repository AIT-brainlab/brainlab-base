# Outputs for AIT Brainlab Management Plane

output "brainlab_zone_name_servers" {
  description = "NS records to delegate to cs.ait.ac.th for brain.cs.ait.ac.th"
  value       = google_dns_managed_zone.brainlab_zone.name_servers
}

output "dpi_zone_name_servers" {
  description = "NS records to delegate to ait.ac.th for dpi.ait.ac.th"
  value       = google_dns_managed_zone.dpi_zone.name_servers
}

output "mgmt_automation_service_account" {
  description = "Email of the management automation service account"
  value       = google_service_account.mgmt_automation_sa.email
}

output "project_owners" {
  description = "List of verified owner accounts on ait-brainlab-mgmt"
  value       = local.authorized_owners
}
