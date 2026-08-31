# ==========================================================
# 🖥️ AIT Brainlab - Proxmox VE IaC Outputs
# ==========================================================

output "dlms_server_vm_id" {
  description = "Proxmox VM ID for DLMS Server"
  value       = proxmox_virtual_environment_vm.dlms_server.vm_id
}

output "dlms_server_vm_name" {
  description = "Proxmox VM Name for DLMS Server"
  value       = proxmox_virtual_environment_vm.dlms_server.name
}

output "brainlab_services_vm_id" {
  description = "Proxmox VM ID for General Lab Services"
  value       = proxmox_virtual_environment_vm.brainlab_services.vm_id
}

output "brainlab_services_vm_name" {
  description = "Proxmox VM Name for General Lab Services"
  value       = proxmox_virtual_environment_vm.brainlab_services.name
}

output "discovered_datastores" {
  description = "Discovered Proxmox host storage pools (Option A Awareness)"
  value       = data.proxmox_virtual_environment_datastores.host_datastores.datastore_ids
}

output "existing_vms_count" {
  description = "Total number of pre-existing VMs discovered on Proxmox node"
  value       = length(data.proxmox_virtual_environment_vms.host_vms.vms)
}

output "host_dns_domain" {
  description = "Discovered Proxmox host search domain"
  value       = data.proxmox_virtual_environment_dns.host_dns.domain
}

