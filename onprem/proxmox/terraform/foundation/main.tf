# ==========================================================
# 🛡️ AIT Brainlab - Proxmox Host Foundation Governance
# ==========================================================
# Manages Proxmox Host Timezone, DNS, and SysAdmin User Permissions
# ==========================================================

# 1. Standardize Proxmox Node Timezone (Asia/Bangkok)
resource "proxmox_virtual_environment_time" "host_time" {
  node_name = var.target_node
  time_zone = "Asia/Bangkok"
}

# 2. Configure Host DNS Resolution
resource "proxmox_virtual_environment_dns" "host_dns" {
  node_name = var.target_node
  domain    = "brain.cs.ait.ac.th"
  servers   = ["192.41.170.1", "8.8.8.8"]
}

# 3. User ACL Assignment for SysAdmin Administrators
resource "proxmox_virtual_environment_acl" "sysadmin_admins" {
  for_each = toset(var.sysadmin_emails)

  path      = "/"
  role_id   = "Administrator"
  user_id   = "${each.value}@google"
  propagate = true
}
