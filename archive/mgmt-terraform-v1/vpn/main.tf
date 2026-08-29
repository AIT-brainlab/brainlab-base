# ==========================================================
# 📡 AIT Brainlab - NetBird-as-Code Mesh VPN Module
# ==========================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    netbird = {
      source  = "netbirdio/netbird"
      version = ">= 0.0.9"
    }
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0"
    }
  }

  # Remote State Backend (Permanent GCS Bucket)
  backend "gcs" {
    bucket = "ait-brainlab-mgmt-tfstate"
    prefix = "vpn"
  }
}

# 1. Google Cloud Provider (for Secret Manager integration)
provider "google" {
  project = var.project_id
  region  = var.region
}

# 🔐 Read NetBird Admin Management Token directly from GCP Secret Manager (Zero secrets on disk!)
data "google_secret_manager_secret_version" "netbird_token" {
  project = var.project_id
  secret  = "netbird-mgmt-token"
  version = "latest"
}

# 2. NetBird Provider (Connecting to Self-Hosted Management Plane)
provider "netbird" {
  management_url = var.netbird_management_url
  token          = data.google_secret_manager_secret_version.netbird_token.secret_data
}
