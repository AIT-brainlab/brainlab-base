output "vm_name" {
  description = "Name of the compute instance"
  value       = google_compute_instance.mgmt_vm.name
}

output "vm_public_ip" {
  description = "Dynamic Ephemeral Public IP assigned to the Management VM"
  value       = google_compute_instance.mgmt_vm.network_interface[0].access_config[0].nat_ip
}

output "lldap_url" {
  description = "URL for the LLDAP Identity Management Portal"
  value       = "https://${var.lldap_subdomain}.${var.domain}"
}

output "netbird_url" {
  description = "URL for the NetBird VPN Control Plane Dashboard"
  value       = "https://${var.netbird_subdomain}.${var.domain}"
}
