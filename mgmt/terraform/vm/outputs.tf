output "vm_name" {
  description = "Name of the compute instance"
  value       = google_compute_instance.mgmt_vm.name
}

output "vm_static_ip" {
  description = "Permanent Public Static IP assigned to the Management Control Plane"
  value       = google_compute_address.mgmt_ip.address
}

output "lldap_staging_url" {
  description = "Staging URL for the LLDAP Identity Management Portal"
  value       = "https://${var.lldap_staging_subdomain}.${var.domain}"
}

output "netbird_staging_url" {
  description = "Staging URL for the NetBird VPN Control Plane Dashboard"
  value       = "https://${var.netbird_staging_subdomain}.${var.domain}"
}

output "lldap_production_url" {
  description = "Production URL for the LLDAP Identity Management Portal"
  value       = "https://${var.lldap_subdomain}.${var.domain}"
}

output "netbird_production_url" {
  description = "Production URL for the NetBird VPN Control Plane Dashboard"
  value       = "https://${var.netbird_subdomain}.${var.domain}"
}
