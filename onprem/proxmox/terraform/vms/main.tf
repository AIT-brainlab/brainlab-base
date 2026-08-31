# ==========================================================
# 🖥️ AIT Brainlab - Proxmox VE Application VM Provisioner
# ==========================================================
# Provisions multi-tenant Application VM on local Proxmox hypervisor
# Provider: bpg/proxmox
# ==========================================================

# 0. Data Sources (Option A: Dynamic Read-Only Proxmox Awareness)
data "proxmox_virtual_environment_datastores" "host_datastores" {
  node_name = var.target_node
}

data "proxmox_virtual_environment_vms" "host_vms" {
  node_name = var.target_node
}

data "proxmox_virtual_environment_dns" "host_dns" {
  node_name = var.target_node
}

# 1. Render and Upload Cloud-Init User-Data Snippet to Proxmox
resource "proxmox_virtual_environment_file" "cloud_user_data" {
  content_type = "snippets"
  datastore_id = var.snippet_datastore_id
  node_name    = var.target_node

  source_raw {
    data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
      vm_name           = var.vm_name
      netbird_setup_key = var.netbird_setup_key
      ssh_public_keys   = var.ssh_public_keys
    })

    file_name = "cloud-init-${var.vm_name}.yaml"
  }
}

# 2. Virtual Machine Definition
resource "proxmox_virtual_environment_vm" "app_vm" {
  name        = var.vm_name
  description = var.vm_description
  node_name   = var.target_node
  vm_id       = var.vm_id
  tags        = ["brainlab", "onprem", "application-vm"]

  # Enable QEMU Guest Agent
  agent {
    enabled = true
  }

  # CPU Configuration
  cpu {
    cores = var.cores
    type  = "host"
  }

  # RAM Allocation
  memory {
    dedicated = var.memory
  }

  # Root SCSI Disk Configuration
  disk {
    datastore_id = var.datastore_id
    file_id      = "local:iso/ubuntu-24.04-minimal-cloudimg-amd64.img"
    interface    = "scsi0"
    size         = var.disk_size
  }

  # Network Interface Bridge (CSIM LAN)
  network_device {
    bridge = var.bridge
  }

  # Cloud-Init Drive & Network Initialization (NAT / DHCP)
  initialization {
    datastore_id = var.datastore_id
    
    ip_config {
      ipv4 {
        address = var.ip_address == "dhcp" ? "dhcp" : var.ip_address
        gateway = var.ip_address == "dhcp" ? null : var.gateway
      }
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_user_data.id
  }
}
