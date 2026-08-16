# Authoritative Cloud DNS Managed Zones for ait-brainlab-mgmt

# Zone 1: brain.cs.ait.ac.th
resource "google_dns_managed_zone" "brainlab_zone" {
  name        = "brainlab-dns-zone"
  dns_name    = "brain.cs.ait.ac.th."
  description = "AIT Brainlab Authoritative DNS Zone"
  visibility  = "public"

  depends_on = [google_project_service.mgmt_services]
}

# Zone 2: dpi.ait.ac.th
resource "google_dns_managed_zone" "dpi_zone" {
  name        = "dpi-dns-zone"
  dns_name    = "dpi.ait.ac.th."
  description = "DPI Center Authoritative DNS Zone"
  visibility  = "public"

  depends_on = [google_project_service.mgmt_services]
}

output "brainlab_name_servers" {
  description = "NS records to delegate to cs.ait.ac.th"
  value       = google_dns_managed_zone.brainlab_zone.name_servers
}

output "dpi_name_servers" {
  description = "NS records to delegate to ait.ac.th"
  value       = google_dns_managed_zone.dpi_zone.name_servers
}
