# ==========================================================
# 🛡️ AIT Brainlab - Proxmox Host Foundation Provider Config
# ==========================================================
# Manages On-Premise Proxmox VE Host Governance & SSO Realms
# Remote State: GCS Bucket gs://ait-brainlab-mgmt-tfstate/onprem/foundation
# ==========================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.60.0"
    }
  }

  backend "gcs" {
    bucket = "ait-brainlab-mgmt-tfstate"
    prefix = "onprem/proxmox/foundation"
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure

  ssh {
    agent    = true
    username = "root"

    node {
      name    = var.target_node
      address = "192.41.170.19"
    }
  }
}
