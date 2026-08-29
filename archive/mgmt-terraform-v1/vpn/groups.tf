# ==========================================================
# 👥 NetBird Device Groups
# ==========================================================

# 1. 🖥️ Servers: All lab compute nodes (la, tokyo), TrueNAS (cairo), and Cloud VM
resource "netbird_group" "servers" {
  name = "servers"
}

# 2. 💻 SysAdmin Devices: Laptops & personal workstations of lab operators
resource "netbird_group" "sysadmin_devices" {
  name = "sysadmin-devices"
}
