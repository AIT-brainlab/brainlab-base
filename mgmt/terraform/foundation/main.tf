# ==========================================================
# 🛡️ AIT Brainlab - Consolidated Cloud Foundation Module
# ==========================================================
# This module manages 100% of the permanent, static GCP cloud
# assets for ait-brainlab-mgmt:
# - Cloud DNS Zones (brain.cs.ait.ac.th, dpi.ait.ac.th) & Records
# - Project IAM Governance & Automation Service Account
# - GCP Secret Manager Keys
#
# INVARIANT: This module is applied ONCE and never destroyed.
# All sensitive and critical resources use prevent_destroy = true.
# ==========================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  backend "gcs" {
    bucket = "ait-brainlab-mgmt-tfstate"
    prefix = "foundation"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
