output "brainlab_name_servers" {
  description = "NS records to delegate to cs.ait.ac.th for brain.cs.ait.ac.th"
  value       = google_dns_managed_zone.brainlab_zone.name_servers
}

output "dpi_name_servers" {
  description = "NS records to delegate to ait.ac.th for dpi.ait.ac.th"
  value       = google_dns_managed_zone.dpi_zone.name_servers
}
