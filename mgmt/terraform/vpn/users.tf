# ==========================================================
# 👤 NetBird Users & Access Control (GitOps Disciplined Model)
# ==========================================================
# 🔒 GITOPS INVARIANT:
# - All network configuration, ACLs, and groups are managed 100% via Terraform.
# - 'brainlab@ait.asia' is the Master Account created during Day-0 bootstrap.
# - All personal SysAdmins have 'role = "user"' with 'auto_groups = [sysadmin-devices]',
#   giving their laptops full SSH & WireGuard network access without risking Web UI drift.
# ==========================================================

# ==========================================================
# 💻 SysAdmin User Accounts (Full WireGuard Access, Zero Web Drift)
# ==========================================================

# Lead SysAdmin: Akraradet (AIT Identity)
resource "netbird_user" "admin_akraradet_ait" {
  is_service_user = false
  name            = "Akraradet Sinsamersuk"
  email           = "st121413@ait.asia"
  role            = "user" # Client VPN access only (prevents accidental Web UI drift)
  auto_groups     = [netbird_group.sysadmin_devices.id]
}

# Lead SysAdmin: Akraradet (Alumni / Emergency Personal Identity)
resource "netbird_user" "admin_akraradet_gmail" {
  is_service_user = false
  name            = "Akraradet Sinsamersuk (Personal)"
  email           = "akraradets@gmail.com"
  role            = "user"
  auto_groups     = [netbird_group.sysadmin_devices.id]
}

# SysAdmin: Phue Pwint Thwe
resource "netbird_user" "admin_phue" {
  is_service_user = false
  name            = "Phue Pwint Thwe"
  email           = "phuepwintthwe@ait.asia"
  role            = "user"
  auto_groups     = [netbird_group.sysadmin_devices.id]
}
