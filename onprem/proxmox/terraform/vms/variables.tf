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
  description = "Number of CPU cores allocated"
  type        = number
  default     = 32
}

variable "memory" {
  description = "RAM allocated in Megabytes (65536 = 64GB)"
  type        = number
  default     = 65536
}

variable "disk_size" {
  description = "Root disk size in Gigabytes"
  type        = number
  default     = 150
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
  description = "DNS nameserver"
  type        = string
  default     = "192.41.170.1"
}

variable "netbird_setup_key" {
  description = "Ephemeral single-use NetBird setup key for automated peer enrollment"
  type        = string
  sensitive   = true
  default     = ""
}

variable "ssh_public_keys" {
  description = "List of SSH public keys for root/admin login"
  type        = list(string)
  default     = []
}
