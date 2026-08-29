# ==========================================================
# 🔑 NetBird Server Setup Keys & GCP Secret Manager Storage
# ==========================================================

# 1. 🖥️ Generate Cryptographic Setup Key in NetBird (365 days, unlimited uses)
resource "netbird_setup_key" "servers" {
  name           = "servers-key"
  type           = "reusable"
  expiry_seconds = 31536000 # 365 days
  auto_groups    = [netbird_group.servers.id]
  usage_limit    = 0        # Unlimited server enrollments
}

# 2. 🔐 Store Server Setup Key in GCP Secret Manager
resource "google_secret_manager_secret" "netbird_setup_key" {
  secret_id = "netbird-setup-key"

  replication {
    auto {}
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_secret_manager_secret_version" "netbird_setup_key_version" {
  secret      = google_secret_manager_secret.netbird_setup_key.id
  secret_data = netbird_setup_key.servers.key
}
