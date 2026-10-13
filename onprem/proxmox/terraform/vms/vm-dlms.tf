# ==========================================================
# 🚀 AIT Brainlab Dedicated Research Workload VM (VM 119)
# ==========================================================
# VM 119: dlms-server (Dedicated AI Vision & Deep Learning Platform)
# Simulates AMD Ryzen 9 9950X (16 vCPUs) & 32GB DDR5 RAM
# ==========================================================

# 1. Variables for VM 119 (dlms-server)
variable "dlms_vm_id" {
  description = "Proxmox VM ID for dlms-server"
  type        = number
  default     = 119
}

variable "dlms_cores" {
  description = "CPU cores allocated for dlms-server (Simulates AMD Ryzen 9 9950X 16 vCPUs)"
  type        = number
  default     = 16
}

variable "dlms_memory" {
  description = "RAM allocated in Megabytes for dlms-server (32768 = 32GB DDR5-5600)"
  type        = number
  default     = 32768
}

variable "dlms_disk_size" {
  description = "Root disk size in Gigabytes for dlms-server"
  type        = number
  default     = 200
}

variable "dlms_ip" {
  description = "Static IP address for dlms-server on vmbr1 (Private LAN)"
  type        = string
  default     = "192.168.1.119/24"
}

variable "dlms_gateway" {
  description = "Default gateway for dlms-server on vmbr1"
  type        = string
  default     = "192.168.1.1"
}

variable "dlms_deploy_ssh_public_keys" {
  description = "List of SSH public keys for DLMS project deployment (deploy user)"
  type        = list(string)
  default = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ3wy6w+Eb0SONJo5DD+tvvCL+oVtg/FuFkbn/z8/yVT deploy@dlms-server"
  ]
}

# 2. Cloud-Init Snippet for VM 119 (dlms-server)
resource "proxmox_virtual_environment_file" "cloud_user_data_dlms" {
  content_type = "snippets"
  datastore_id = var.snippet_datastore_id
  node_name    = var.target_node

  source_raw {
    data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
      vm_name                = "dlms-server"
      admin_ssh_public_keys  = var.admin_ssh_public_keys
      deploy_ssh_public_keys = var.dlms_deploy_ssh_public_keys
      dynamic_routes_yaml    = ""
    })

    file_name = "cloud-init-dlms-server.yaml"
  }
}

# 3. VM 119: Dedicated DLMS Server (AI Vision & Deep Learning Services)
resource "proxmox_virtual_environment_vm" "dlms_server" {
  name        = "dlms-server"
  description = "Dedicated DLMS Server VM (Deep Learning & AI Vision Services - Ryzen 9950X / 32GB Simulation)"
  node_name   = var.target_node
  vm_id       = var.dlms_vm_id
  tags        = ["brainlab", "onprem", "dlms", "gpu-ready"]

  agent {
    enabled = true
    timeout = "1s"
  }

  cpu {
    cores = var.dlms_cores
    type  = "host"
  }

  memory {
    dedicated = var.dlms_memory
  }

  disk {
    datastore_id = var.datastore_id
    file_id      = "local:iso/ubuntu-24.04-minimal-cloudimg-amd64.img"
    interface    = "scsi0"
    size         = var.dlms_disk_size
  }

  network_device {
    bridge = "vmbr1"
  }

  initialization {
    datastore_id = var.datastore_id

    ip_config {
      ipv4 {
        address = var.dlms_ip
        gateway = var.dlms_gateway
      }
    }

    dns {
      servers = ["192.168.1.1", "192.41.170.15", "8.8.8.8"]
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_user_data_dlms.id
  }

  lifecycle {
    ignore_changes = [
      initialization[0].user_data_file_id,
    ]
  }
}
