# ==========================================================
# 📤 Foundation Module Outputs
# ==========================================================

# IAM
output "project_owners" {
  description = "List of verified owner accounts on ait-brainlab-mgmt"
  value       = local.authorized_owners
}

output "terraform_service_account" {
  description = "Email of the management Terraform service account"
  value       = google_service_account.mgmt_terraform_sa.email
}

# DNS
output "brainlab_name_servers" {
  description = "NS records for brain.cs.ait.ac.th"
  value       = google_dns_managed_zone.brainlab_zone.name_servers
}

output "dpi_name_servers" {
  description = "NS records for dpi.ait.ac.th"
  value       = google_dns_managed_zone.dpi_zone.name_servers
}

# Secrets
output "jwt_secret_id" {
  description = "Secret Manager ID for LLDAP JWT secret"
  value       = google_secret_manager_secret.jwt_secret.secret_id
}

output "admin_password_secret_id" {
  description = "Secret Manager ID for LLDAP Admin password"
  value       = google_secret_manager_secret.admin_password.secret_id
}

output "google_oauth_client_id_secret_id" {
  description = "Secret Manager ID for Google OAuth Client ID"
  value       = google_secret_manager_secret.google_oauth_client_id.secret_id
}

output "google_oauth_client_secret_secret_id" {
  description = "Secret Manager ID for Google OAuth Client Secret"
  value       = google_secret_manager_secret.google_oauth_client_secret.secret_id
}

output "netbird_setup_key_secret_id" {
  description = "Secret Manager ID for NetBird Setup Key"
  value       = google_secret_manager_secret.netbird_setup_key.secret_id
}
