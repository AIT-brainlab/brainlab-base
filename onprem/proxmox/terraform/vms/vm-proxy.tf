# ==========================================================
# 🌐 VM 100: AIT Brainlab 10G Edge Proxy (brainlab-proxy)
# ==========================================================
# Public-facing Traefik v3 Edge Ingress & SSL Termination Proxy
# Dual-homed: net0 on 10G CSIM LAN (vmbr1) & net1 on internal SDN
# ==========================================================

# 1. Variables for VM 100 (brainlab-proxy)
variable "proxy_vm_id" {
  description = "Proxmox VM ID for brainlab-proxy"
  type        = number
  default     = 100
}

variable "proxy_cores" {
  description = "CPU cores allocated for VM 100 (proxy)"
  type        = number
  default     = 4
}

variable "proxy_memory" {
  description = "RAM allocated in Megabytes for VM 100 (8192 = 8GB)"
  type        = number
  default     = 8192
}

variable "proxy_disk_size" {
  description = "Root disk size in Gigabytes for VM 100"
  type        = number
  default     = 50
}

variable "proxy_ip" {
  description = "Static IP address for VM 100 on vmbr1 (Private LAN)"
  type        = string
  default     = "192.168.1.100/24"
}

variable "proxy_gateway" {
  description = "Gateway for vmbr1 (Router LAN IP)"
  type        = string
  default     = "192.168.1.1"
}

variable "proxy_sdn_ip" {
  description = "Static IP address for VM 100 on internal Proxmox SDN NAT VNet"
  type        = string
  default     = "10.10.250.100/16"
}

variable "proxy_netbird_host" {
  description = "NetBird MagicDNS hostname or IP for brainlab-proxy VM (VM 100)"
  type        = string
  default     = "brainlab-proxy"
}

# 2. Cloud-Init Snippet for VM 100
resource "proxmox_virtual_environment_file" "cloud_user_data_proxy" {
  content_type = "snippets"
  datastore_id = var.snippet_datastore_id
  node_name    = var.target_node

  source_raw {
    data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
      vm_name                = "brainlab-proxy"
      admin_ssh_public_keys  = var.admin_ssh_public_keys
      deploy_ssh_public_keys = []
      dynamic_routes_yaml    = ""
    })

    file_name = "cloud-init-brainlab-proxy.yaml"
  }
}

# 3. Proxmox Virtual Machine Resource (VM 100)
resource "proxmox_virtual_environment_vm" "proxy" {
  name        = "brainlab-proxy"
  description = "AIT Brainlab On-Premise 10G Edge Proxy VM (Traefik SSL/HTTP Edge Proxy)"
  node_name   = var.target_node
  vm_id       = var.proxy_vm_id
  tags        = ["brainlab", "onprem", "proxy", "edge"]

  agent {
    enabled = true
    timeout = "1s"
  }

  cpu {
    cores = var.proxy_cores
    type  = "host"
  }

  memory {
    dedicated = var.proxy_memory
  }

  disk {
    datastore_id = var.datastore_id
    file_id      = "local:iso/ubuntu-24.04-minimal-cloudimg-amd64.img"
    interface    = "scsi0"
    size         = var.proxy_disk_size
  }

  # net0: Frontend Physical 10G CSIM LAN
  network_device {
    bridge = "vmbr1"
  }

  # net1: Internal Proxmox SDN NAT VNet (direct L2 access to tenant VMs)
  network_device {
    bridge = var.bridge
  }

  initialization {
    datastore_id = var.datastore_id

    ip_config {
      ipv4 {
        address = var.proxy_ip
        gateway = var.proxy_gateway
      }
    }

    ip_config {
      ipv4 {
        address = var.proxy_sdn_ip
      }
    }

    dns {
      servers = ["192.41.170.15"]
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_user_data_proxy.id
  }

  lifecycle {
    ignore_changes = [
      initialization[0].user_data_file_id,
    ]
  }
}
