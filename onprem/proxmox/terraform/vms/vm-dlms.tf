# ==========================================================
# 🚀 AIT Brainlab Dedicated Research Workload VM (VM 119)
# ==========================================================
# VM 119: dlms-server (Dedicated AI Vision & Deep Learning Platform)
# Simulates AMD Ryzen 9 9950X (16 vCPUs) & 32GB DDR5 RAM
# ==========================================================

# 1. Cloud-Init Snippet for VM 119 (dlms-server)
resource "proxmox_virtual_environment_file" "cloud_user_data_dlms" {
  content_type = "snippets"
  datastore_id = var.snippet_datastore_id
  node_name    = var.target_node

  source_raw {
    data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
      vm_name             = "dlms-server"
      netbird_setup_key   = var.netbird_dlms_servers_key
      ssh_public_keys     = var.ssh_public_keys
      dynamic_routes_yaml = ""
    })

    file_name = "cloud-init-dlms-server.yaml"
  }
}

# 2. VM 119: Dedicated DLMS Server (AI Vision & Deep Learning Services)
resource "proxmox_virtual_environment_vm" "dlms_server" {
  name        = "dlms-server"
  description = "Dedicated DLMS Server VM (Deep Learning & AI Vision Services - Ryzen 9950X / 32GB Simulation)"
  node_name   = var.target_node
  vm_id       = 119
  tags        = ["brainlab", "onprem", "dlms", "gpu-ready"]

  agent {
    enabled = true
    timeout = "1s"
  }

  cpu {
    cores = var.cores
    type  = "host"
  }

  memory {
    dedicated = var.memory
  }

  disk {
    datastore_id = var.datastore_id
    file_id      = "local:iso/ubuntu-24.04-minimal-cloudimg-amd64.img"
    interface    = "scsi0"
    size         = var.disk_size
  }

  network_device {
    bridge = var.bridge
  }

  initialization {
    datastore_id = var.datastore_id

    ip_config {
      ipv4 {
        address = "10.10.250.119/16"
        gateway = "10.10.0.1"
      }
    }

    dns {
      servers = ["192.41.170.15", "8.8.8.8"]
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_user_data_dlms.id
  }

  lifecycle {
    ignore_changes = [
      initialization[0].user_data_file_id,
    ]
  }
}
