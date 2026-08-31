# ==========================================================
# 🖥️ AIT Brainlab - Proxmox VE IaC Outputs
# ==========================================================

output "vm_id" {
  description = "Proxmox VM ID"
  value       = proxmox_virtual_environment_vm.app_vm.vm_id
}

output "vm_name" {
  description = "Proxmox VM Name"
  value       = proxmox_virtual_environment_vm.app_vm.name
}

output "vm_ip_address" {
  description = "Static IP Address on CSIM LAN"
  value       = var.ip_address
}

output "node_name" {
  description = "Target Proxmox Hypervisor Node"
  value       = proxmox_virtual_environment_vm.app_vm.node_name
}

output "mac_address" {
  description = "Network interface MAC address"
  value       = proxmox_virtual_environment_vm.app_vm.network_device[0].mac_address
}
