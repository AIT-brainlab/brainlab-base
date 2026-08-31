# ==========================================================
# 🛡️ AIT Brainlab - Proxmox Host Foundation Outputs
# ==========================================================

output "node_name" {
  description = "Target Proxmox hypervisor node"
  value       = var.target_node
}

output "time_zone" {
  description = "Host timezone"
  value       = proxmox_virtual_environment_time.host_time.time_zone
}

output "dns_domain" {
  description = "Host search domain"
  value       = proxmox_virtual_environment_dns.host_dns.domain
}

output "sysadmin_admins" {
  description = "Configured SysAdmin accounts on Proxmox"
  value       = var.sysadmin_emails
}
