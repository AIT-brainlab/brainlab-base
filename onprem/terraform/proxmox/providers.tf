# ==========================================================
# 🖥️ AIT Brainlab - Proxmox VE Terraform Provider Config
# ==========================================================
# Manages On-Premise Proxmox VE Virtual Machines & LXC Containers
# Uses official modern provider: bpg/proxmox
# ==========================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.60.0"
    }
  }

  # Local or remote GCS backend prefix for on-premise state
  backend "gcs" {
    bucket = "ait-brainlab-mgmt-tfstate"
    prefix = "onprem/proxmox"
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure

  ssh {
    agent    = true
    username = "root"
  }
}
