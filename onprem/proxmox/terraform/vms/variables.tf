# ==========================================================
# 🖥️ AIT Brainlab - Proxmox VE Shared Infrastructure Variables
# ==========================================================
# Common Hypervisor, Storage, SDN & Ingress Variables
# (Per-VM hardware, IDs & network variables are defined directly
# within their respective vm-*.tf files)
# ==========================================================

# 1. Proxmox VE Provider Connection Settings
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

# 2. Storage & Datastore Pools
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

# 3. Base Hypervisor Network & DNS Defaults
variable "bridge" {
  description = "Network bridge interface on Proxmox node (Proxmox SDN VNet)"
  type        = string
  default     = "internet"
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

# 4. Global Administrative Credentials
variable "admin_ssh_public_keys" {
  description = "List of SSH public keys for master admin login (ubuntu user)"
  type        = list(string)
  default = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDJDfu8nCfNFJsoHyYK3WMn194MmH/1i/OyhqyhqEbK+ brainlab-admin-key"
  ]
}

# 5. Declarative Ingress Reverse Proxy Routes
variable "proxy_routes" {
  description = "Declarative map of reverse proxy routes managed by brainlab-proxy (domain -> upstream target URL)"
  type = map(object({
    domain        = string
    target_url    = string
    aliases       = optional(list(string), [])
    rule_override = optional(string, "")
    middlewares   = optional(list(string))
    enable_tls    = optional(bool, true)
  }))
  default = {
    dlms = {
      domain     = "dlms.brain.cs.ait.ac.th"
      target_url = "http://192.168.1.118:80"
      aliases = [
        "traefik.dlms.brain.cs.ait.ac.th",
        "back.dlms.brain.cs.ait.ac.th",
        "iobox.dlms.brain.cs.ait.ac.th",
        "cambox.dlms.brain.cs.ait.ac.th",
        "iobox.dlms.brain.cs.ait.ac.th",
        "detector-1.dlms.brain.cs.ait.ac.th",
        "detector-2.dlms.brain.cs.ait.ac.th",
        "bus.dlms.brain.cs.ait.ac.th",
        "rabbitmq.dlms.brain.cs.ait.ac.th",
      ]
      rule_override = ""
      middlewares   = ["rate-limit"]
      enable_tls    = false
    }
    dlms_stg = {
      domain     = "dlms-stg.brain.cs.ait.ac.th"
      target_url = "http://192.168.1.119:80"
      aliases = [
        "traefik.dlms-stg.brain.cs.ait.ac.th",
        "back.dlms-stg.brain.cs.ait.ac.th",
        "iobox.dlms-stg.brain.cs.ait.ac.th",
        "cambox.dlms-stg.brain.cs.ait.ac.th",
        "iobox.dlms-stg.brain.cs.ait.ac.th",
        "detector-1.dlms-stg.brain.cs.ait.ac.th",
        "detector-2.dlms-stg.brain.cs.ait.ac.th",
        "bus.dlms-stg.brain.cs.ait.ac.th",
        "rabbitmq.dlms-stg.brain.cs.ait.ac.th",
      ]
      rule_override = ""
      middlewares   = ["rate-limit"]
      enable_tls    = false
    }
  }
}
