# ==========================================================
# 🛡️ AIT Brainlab - Proxmox Host Foundation Variables
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
  description = "Allow TLS connection without verified CA certificate"
  type        = bool
  default     = true
}

variable "target_node" {
  description = "Target Proxmox VE node name"
  type        = string
  default     = "proxmox"
}

variable "google_oauth_client_id" {
  description = "Google OAuth2 Client ID for Proxmox OpenID Connect Realm"
  type        = string
  default     = ""
}

variable "google_oauth_client_secret" {
  description = "Google OAuth2 Client Secret for Proxmox OpenID Connect Realm"
  type        = string
  sensitive   = true
  default     = ""
}

variable "sysadmin_emails" {
  description = "List of SysAdmin Google emails granted Administrator role on Proxmox"
  type        = list(string)
  default     = ["akraradet@ait.asia", "brainlab@ait.asia"]
}
