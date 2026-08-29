# ==========================================================
# 📡 NetBird VPN Module Outputs
# ==========================================================

output "group_ids" {
  description = "NetBird device group IDs"
  value = {
    servers          = netbird_group.servers.id
    sysadmin_devices = netbird_group.sysadmin_devices.id
  }
}

output "policy_ids" {
  description = "NetBird Zero-Trust ACL policy IDs"
  value = {
    servers_mesh    = netbird_policy.servers_mesh.id
    sysadmin_access = netbird_policy.sysadmin_access.id
  }
}

output "server_setup_key_id" {
  description = "Setup key ID for servers inside NetBird"
  value       = netbird_setup_key.servers.id
}

output "secret_manager_setup_key_id" {
  description = "GCP Secret Manager ID for the NetBird Server Setup Key"
  value       = google_secret_manager_secret.netbird_setup_key.secret_id
}
