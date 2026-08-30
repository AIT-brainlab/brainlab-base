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
  description = "Subdomain for LLDAP Directory Service"
  type        = string
  default     = "ldap"
}

variable "netbird_subdomain" {
  description = "Subdomain for NetBird VPN Control Plane"
  type        = string
  default     = "netbird"
}

variable "acme_email" {
  description = "Email address for automated Let's Encrypt SSL certificate registration"
  type        = string
  default     = "brainlab@ait.asia"
}

variable "state_bucket" {
  description = "GCS bucket name for state and database backups"
  type        = string
  default     = "ait-brainlab-mgmt-tfstate"
}

variable "netbird_version" {
  description = "Version tag for NetBird Management, Signal, and Client"
  type        = string
  default     = "0.77.0"
}

variable "lldap_version" {
  description = "Version tag for LLDAP directory container"
  type        = string
  default     = "2026-08-10-debian"
}

variable "traefik_version" {
  description = "Version tag for Traefik reverse proxy"
  type        = string
  default     = "v3.7"
}

