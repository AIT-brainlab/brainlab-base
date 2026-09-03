# ==========================================================
# 🖨️ VM 120: AIT Brainlab General Services (brainlab-services)
# ==========================================================
# General Lab Administrative Services (Web Printing Portal & Lab Tools)
# Dedicated IP on internal Proxmox SDN NAT VNet: 10.10.250.120
# ==========================================================

# 1. Cloud-Init Snippet for VM 120
resource "proxmox_virtual_environment_file" "cloud_user_data_services" {
  content_type = "snippets"
  datastore_id = var.snippet_datastore_id
  node_name    = var.target_node

  source_raw {
    data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
      vm_name                = "brainlab-services"
      admin_ssh_public_keys  = var.admin_ssh_public_keys
      deploy_ssh_public_keys = []
      dynamic_routes_yaml    = ""
    })

    file_name = "cloud-init-brainlab-services.yaml"
  }
}

# 2. Proxmox Virtual Machine Resource (VM 120)
resource "proxmox_virtual_environment_vm" "brainlab_services" {
  name        = "brainlab-services"
  description = "AIT Brainlab General Services VM (Web Printing Portal & Lab Administration)"
  node_name   = var.target_node
  vm_id       = 120
  tags        = ["brainlab", "onprem", "services", "web-print"]

  agent {
    enabled = true
    timeout = "1s"
  }

  cpu {
    cores = var.services_cores
    type  = "host"
  }

  memory {
    dedicated = var.services_memory
  }

  disk {
    datastore_id = var.datastore_id
    file_id      = "local:iso/ubuntu-24.04-minimal-cloudimg-amd64.img"
    interface    = "scsi0"
    size         = var.services_disk_size
  }

  network_device {
    bridge = var.bridge
  }

  initialization {
    datastore_id = var.datastore_id

    ip_config {
      ipv4 {
        address = "10.10.250.120/16"
        gateway = "10.10.0.1"
      }
    }

    dns {
      servers = ["192.41.170.15", "8.8.8.8"]
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_user_data_services.id
  }

  lifecycle {
    ignore_changes = [
      initialization[0].user_data_file_id,
    ]
  }
}
