output "jwt_secret_id" {
  description = "Secret Manager ID for LLDAP JWT secret"
  value       = google_secret_manager_secret.jwt_secret.secret_id
}

output "admin_password_secret_id" {
  description = "Secret Manager ID for LLDAP Admin password"
  value       = google_secret_manager_secret.admin_password.secret_id
}

output "netbird_key_secret_id" {
  description = "Secret Manager ID for NetBird Setup Key"
  value       = google_secret_manager_secret.netbird_key_secret.secret_id
}
