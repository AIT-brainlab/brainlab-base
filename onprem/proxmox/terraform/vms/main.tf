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

# 1. Cloud-Init Snippet for VM 119 (dlms-server)
resource "proxmox_virtual_environment_file" "cloud_user_data_dlms" {
  content_type = "snippets"
  datastore_id = var.snippet_datastore_id
  node_name    = var.target_node

  source_raw {
    data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
      vm_name           = "dlms-server"
      netbird_setup_key = var.netbird_setup_key
      ssh_public_keys   = var.ssh_public_keys
    })

    file_name = "cloud-init-dlms-server.yaml"
  }
}

# 2. Cloud-Init Snippet for VM 120 (brainlab-services)
resource "proxmox_virtual_environment_file" "cloud_user_data_services" {
  content_type = "snippets"
  datastore_id = var.snippet_datastore_id
  node_name    = var.target_node

  source_raw {
    data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
      vm_name           = "brainlab-services"
      netbird_setup_key = var.netbird_services_setup_key != "" ? var.netbird_services_setup_key : var.netbird_setup_key
      ssh_public_keys   = var.ssh_public_keys
    })

    file_name = "cloud-init-brainlab-services.yaml"
  }
}

# 3. VM 119: Dedicated DLMS Server (AI Vision & Deep Learning Services)
resource "proxmox_virtual_environment_vm" "dlms_server" {
  name        = "dlms-server"
  description = "Dedicated DLMS Server VM (Deep Learning & AI Vision Services - Ryzen 9950X / 32GB Simulation)"
  node_name   = var.target_node
  vm_id       = 119
  tags        = ["brainlab", "onprem", "dlms", "gpu-ready"]

  agent {
    enabled = true
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
        address = "dhcp"
      }
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_user_data_dlms.id
  }
}

# 4. VM 120: General Lab Administrative Services (Web Printing Portal & Lab Tools)
resource "proxmox_virtual_environment_vm" "brainlab_services" {
  name        = "brainlab-services"
  description = "AIT Brainlab General Services VM (Web Printing Portal & Lab Administration)"
  node_name   = var.target_node
  vm_id       = 120
  tags        = ["brainlab", "onprem", "services", "web-print"]

  agent {
    enabled = true
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
        address = "dhcp"
      }
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_user_data_services.id
  }
}
