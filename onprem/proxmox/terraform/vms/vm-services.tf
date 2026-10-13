# ==========================================================
# 🖨️ VM 120: AIT Brainlab General Services (brainlab-services)
# ==========================================================
# General Lab Administrative Services (Web Printing Portal & Lab Tools)
# Dedicated IP on internal Proxmox SDN NAT VNet: 10.10.250.120
# ==========================================================

# 1. Variables for VM 120 (brainlab-services)
variable "services_vm_id" {
  description = "Proxmox VM ID for brainlab-services"
  type        = number
  default     = 120
}

variable "services_cores" {
  description = "CPU cores allocated for VM 120 (brainlab-services)"
  type        = number
  default     = 4
}

variable "services_memory" {
  description = "RAM allocated in Megabytes for VM 120 (8192 = 8GB)"
  type        = number
  default     = 8192
}

variable "services_disk_size" {
  description = "Root disk size in Gigabytes for VM 120"
  type        = number
  default     = 60
}

variable "services_ip" {
  description = "Static IP address for VM 120 on internal Proxmox SDN NAT VNet"
  type        = string
  default     = "10.10.250.120/16"
}

variable "services_gateway" {
  description = "Gateway for VM 120 on internal Proxmox SDN NAT VNet"
  type        = string
  default     = "10.10.0.1"
}

# 2. Cloud-Init Snippet for VM 120
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

# 3. Proxmox Virtual Machine Resource (VM 120)
resource "proxmox_virtual_environment_vm" "brainlab_services" {
  name        = "brainlab-services"
  description = "AIT Brainlab General Services VM (Web Printing Portal & Lab Administration)"
  node_name   = var.target_node
  vm_id       = var.services_vm_id
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
        address = var.services_ip
        gateway = var.services_gateway
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
