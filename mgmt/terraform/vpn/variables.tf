# ==========================================================
# 📡 NetBird VPN Module Input Variables
# ==========================================================

variable "project_id" {
  type        = string
  description = "GCP Project ID for Management Control Plane"
  default     = "ait-brainlab-mgmt"
}

variable "region" {
  type        = string
  description = "GCP primary deployment region"
  default     = "asia-southeast1"
}

variable "zone" {
  type        = string
  description = "GCP compute zone where the Management VM resides"
  default     = "asia-southeast1-a"
}

variable "netbird_management_url" {
  type        = string
  description = "URL of the Self-Hosted NetBird Management API endpoint"
  default     = "https://netbird2.brain.cs.ait.ac.th"
}

variable "netbird_client_version" {
  type        = string
  description = "Docker image tag for netbird-client peer container"
  default     = "0.77.0"
}
