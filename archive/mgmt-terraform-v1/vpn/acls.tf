# ==========================================================
# 🛡️ NetBird Zero-Trust Access Control Policies (ACLs)
# ==========================================================

# 1. 🖥️ Servers Full Mesh: Allows all servers to communicate freely (LDAP, TrueNAS NFS, Training)
resource "netbird_policy" "servers_mesh" {
  name        = "Servers Full Mesh"
  description = "Allows full mesh communication between all compute nodes, TrueNAS storage, and Cloud VM"
  enabled     = true

  rule {
    name          = "All Traffic Between Servers"
    enabled       = true
    action        = "accept"
    protocol      = "all"
    bidirectional = true
    sources       = [netbird_group.servers.id]
    destinations  = [netbird_group.servers.id]
  }
}

# 2. 💻 SysAdmin Device Access: Allows SysAdmin laptops to connect to all servers
resource "netbird_policy" "sysadmin_access" {
  name        = "SysAdmin Access to Servers"
  description = "Allows SysAdmin laptops full SSH, web, and management access to all servers"
  enabled     = true

  rule {
    name          = "SysAdmin Devices to Servers"
    enabled       = true
    action        = "accept"
    protocol      = "all"
    bidirectional = true
    sources       = [netbird_group.sysadmin_devices.id]
    destinations  = [netbird_group.servers.id]
  }
}
