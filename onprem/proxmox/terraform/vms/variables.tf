# ==========================================================
# 🖥️ AIT Brainlab - Proxmox VE Terraform Variables
# ==========================================================

variable "proxmox_endpoint" {
  description = "Proxmox VE API endpoint URL"
  type        = string
  default     = "https://192.41.170.19:8006/"
}

variable "proxmox_api_token" {
  description = "Proxmox VE API Token ID and Secret (format: USER@REALM!TOKENID=UUID)"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Allow TLS connection without verified CA certificate (CSIM LAN)"
  type        = bool
  default     = true
}

variable "target_node" {
  description = "Target Proxmox VE node name"
  type        = string
  default     = "proxmox"
}

variable "vm_id" {
  description = "Unique ID for the virtual machine on Proxmox VE"
  type        = number
  default     = 119
}

variable "vm_name" {
  description = "Virtual Machine hostname/name"
  type        = string
  default     = "brainlab-app-vm"
}

variable "vm_description" {
  description = "Proxmox VM note / description"
  type        = string
  default     = "AIT Brainlab On-Premise Shared Application VM (Web Print & DLMS Containers)"
}

variable "cores" {
  description = "Number of CPU cores allocated (Simulates AMD Ryzen 9 9950X 16 vCPUs)"
  type        = number
  default     = 16
}

variable "memory" {
  description = "RAM allocated in Megabytes (32768 = 32GB DDR5-5600)"
  type        = number
  default     = 32768
}

variable "disk_size" {
  description = "Root disk size in Gigabytes"
  type        = number
  default     = 200
}

variable "datastore_id" {
  description = "Proxmox datastore pool ID for VM disk storage"
  type        = string
  default     = "WDBlue"
}

variable "snippet_datastore_id" {
  description = "Proxmox datastore ID for Cloud-Init snippet storage"
  type        = string
  default     = "local"
}

variable "bridge" {
  description = "Network bridge interface on Proxmox node (Proxmox SDN VNet)"
  type        = string
  default     = "internet"
}

variable "ip_address" {
  description = "IP address configuration for the VM (CIDR notation or 'dhcp' for automated SDN DHCP)"
  type        = string
  default     = "dhcp"
}

variable "gateway" {
  description = "Default network gateway for Proxmox SDN bridge (internet)"
  type        = string
  default     = "10.10.20.1"
}

variable "nameserver" {
  description = "DNS nameserver (CSIM DNS)"
  type        = string
  default     = "192.41.170.15"
}

variable "admin_ssh_public_keys" {
  description = "List of SSH public keys for master admin login (ubuntu user)"
  type        = list(string)
  default = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDJDfu8nCfNFJsoHyYK3WMn194MmH/1i/OyhqyhqEbK+ brainlab-admin-key"
  ]
}

variable "dlms_deploy_ssh_public_keys" {
  description = "List of SSH public keys for DLMS project deployment (deploy user)"
  type        = list(string)
  default = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ3wy6w+Eb0SONJo5DD+tvvCL+oVtg/FuFkbn/z8/yVT deploy@dlms-server"
  ]
}

# General Lab Services VM (VM 120) Specifications
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

# On-Premise 10G Edge Proxy VM (VM 100) Specifications
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
  description = "Static IP address for VM 100 on vmbr1 CSIM LAN"
  type        = string
  default     = "192.41.170.39/24"
}

variable "proxy_gateway" {
  description = "Gateway for vmbr1 CSIM LAN"
  type        = string
  default     = "192.41.170.23"
}

variable "proxy_routes" {
  description = "Declarative map of reverse proxy routes managed by brainlab-proxy (domain -> upstream target URL)"
  type = map(object({
    domain        = string
    target_url    = string
    aliases       = optional(list(string), [])
    rule_override = optional(string, "")
  }))
  default = {
    dlms = {
      domain        = "dlms.brain.cs.ait.ac.th"
      target_url    = "http://10.10.250.119:80"
      aliases       = [
        "front.dlms.brain.cs.ait.ac.th",
        "back.dlms.brain.cs.ait.ac.th",
        "iobox.dlms.brain.cs.ait.ac.th"
      ]
      rule_override = ""
    }
    services = {
      domain        = "print.brain.cs.ait.ac.th"
      target_url    = "http://10.10.250.120:80"
      aliases       = []
      rule_override = ""
    }
    example = {
      domain        = "example.brain.cs.ait.ac.th"
      target_url    = "http://10.10.250.120:80"
      aliases       = []
      rule_override = ""
    }
  }
}

variable "proxy_netbird_host" {
  description = "NetBird MagicDNS hostname or IP for brainlab-proxy VM (VM 100)"
  type        = string
  default     = "brainlab-proxy"
}
