# Secret Manager Secrets for Identity Management & NetBird

# Random Secret Generators
resource "random_password" "lldap_jwt_secret" {
  length  = 32
  special = false
}

resource "random_password" "lldap_admin_password" {
  length  = 24
  special = true
}

# Secret 1: LLDAP JWT Secret Key (Protected against destroy)
resource "google_secret_manager_secret" "jwt_secret" {
  secret_id = "lldap-jwt-secret"

  replication {
    auto {}
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_project_service.mgmt_services]
}

resource "google_secret_manager_secret_version" "jwt_secret_version" {
  secret      = google_secret_manager_secret.jwt_secret.id
  secret_data = random_password.lldap_jwt_secret.result
}

# Secret 2: LLDAP Admin Initial Password (Protected against destroy)
resource "google_secret_manager_secret" "admin_password" {
  secret_id = "lldap-admin-password"

  replication {
    auto {}
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_project_service.mgmt_services]
}

resource "google_secret_manager_secret_version" "admin_password_version" {
  secret      = google_secret_manager_secret.admin_password.id
  secret_data = random_password.lldap_admin_password.result
}

# Secret 3: NetBird Server Setup Key (Protected against destroy)
resource "google_secret_manager_secret" "netbird_key_secret" {
  secret_id = "netbird-onprem-setup-key"

  replication {
    auto {}
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_project_service.mgmt_services]
}

resource "google_secret_manager_secret_version" "netbird_key_version" {
  secret      = google_secret_manager_secret.netbird_key_secret.id
  secret_data = "INITIAL_SETUP_KEY_PLACEHOLDER"
}
