variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
  default     = "ait-brainlab-mgmt"
}

variable "region" {
  description = "GCP region for compute instance and static IP"
  type        = string
  default     = "asia-southeast1"
}

variable "zone" {
  description = "GCP zone for the VM"
  type        = string
  default     = "asia-southeast1-a"
}

variable "machine_type" {
  description = "Compute instance machine type (e2-micro = 1GB RAM Free Tier eligible, e2-small = 2GB RAM)"
  type        = string
  default     = "e2-micro"
}

variable "domain" {
  description = "Base root lab domain"
  type        = string
  default     = "brain.cs.ait.ac.th"
}

variable "lldap_subdomain" {
  description = "Production subdomain for LLDAP"
  type        = string
  default     = "authen"
}

variable "lldap_staging_subdomain" {
  description = "Staging/Canary subdomain for LLDAP"
  type        = string
  default     = "authen2"
}

variable "netbird_subdomain" {
  description = "Production subdomain for NetBird VPN"
  type        = string
  default     = "netbird"
}

variable "netbird_staging_subdomain" {
  description = "Staging/Canary subdomain for NetBird VPN"
  type        = string
  default     = "netbird2"
}

variable "acme_email" {
  description = "Email address for automated Let's Encrypt SSL certificate registration"
  type        = string
  default     = "brainlab@ait.asia"
}
