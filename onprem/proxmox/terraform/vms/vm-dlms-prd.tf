# ==========================================================
# 🚀 VM 118: dlms-prd (Production AI Vision & Deep Learning)
# ==========================================================
# Docker Swarm Node (Simulates AMD Ryzen 9 9950X 16 vCPUs & 32GB RAM)
# ==========================================================

# 1. Variables for VM 118 (dlms-prd)
variable "dlms_prd_vm_id" {
  description = "Proxmox VM ID for dlms-prd"
  type        = number
  default     = 118
}

variable "dlms_prd_cores" {
  description = "CPU cores allocated for dlms-prd (Simulates AMD Ryzen 9 9950X 16 vCPUs)"
  type        = number
  default     = 16
}

variable "dlms_prd_memory" {
  description = "RAM allocated in Megabytes for dlms-prd (32768 = 32GB DDR5)"
  type        = number
  default     = 32768
}

variable "dlms_prd_disk_size" {
  description = "Root disk size in Gigabytes for dlms-prd"
  type        = number
  default     = 200
}

variable "dlms_prd_ip" {
  description = "Static IP address for dlms-prd on vmbr1 (Private LAN)"
  type        = string
  default     = "192.168.1.118/24"
}

variable "dlms_prd_gateway" {
  description = "Default gateway for dlms-prd on vmbr1"
  type        = string
  default     = "192.168.1.1"
}

# 2. Cloud-Init Snippet for VM 118 (dlms-prd)
resource "proxmox_virtual_environment_file" "cloud_user_data_dlms_prd" {
  content_type = "snippets"
  datastore_id = var.snippet_datastore_id
  node_name    = var.target_node

  source_raw {
    data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
      vm_name                = "dlms-prd"
      admin_ssh_public_keys  = var.admin_ssh_public_keys
      deploy_ssh_public_keys = var.dlms_deploy_ssh_public_keys
      dynamic_routes_yaml    = ""
    })

    file_name = "cloud-init-dlms-prd.yaml"
  }
}

# 3. VM 118: Production DLMS Server (AI Vision & Deep Learning Services - Docker Swarm Node)
resource "proxmox_virtual_environment_vm" "dlms_prd" {
  name        = "dlms-prd"
  description = "Production DLMS Server VM (Docker Swarm Node - AI Vision & Deep Learning)"
  node_name   = var.target_node
  vm_id       = var.dlms_prd_vm_id
  tags        = ["brainlab", "onprem", "dlms", "prd", "swarm", "gpu-ready"]

  agent {
    enabled = true
    timeout = "1s"
  }

  cpu {
    cores = var.dlms_prd_cores
    type  = "host"
  }

  memory {
    dedicated = var.dlms_prd_memory
  }

  disk {
    datastore_id = var.datastore_id
    file_id      = "local:iso/ubuntu-24.04-minimal-cloudimg-amd64.img"
    interface    = "scsi0"
    size         = var.dlms_prd_disk_size
  }

  network_device {
    bridge = "vmbr1"
  }

  initialization {
    datastore_id = var.datastore_id

    ip_config {
      ipv4 {
        address = var.dlms_prd_ip
        gateway = var.dlms_prd_gateway
      }
    }

    dns {
      servers = ["192.168.1.1", "192.41.170.15", "8.8.8.8"]
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_user_data_dlms_prd.id
  }

  lifecycle {
    ignore_changes = [
      initialization[0].user_data_file_id,
    ]
  }
}
