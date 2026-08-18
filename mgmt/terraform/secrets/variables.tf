variable "project_id" {
  type        = string
  description = "GCP Project ID for Management Plane"
  default     = "ait-brainlab-mgmt"
}

variable "region" {
  type        = string
  description = "GCP Region"
  default     = "asia-southeast1"
}

variable "google_oauth_client_id" {
  type        = string
  description = "Optional: Google OAuth 2.0 Web Client ID to automatically seed into Secret Manager"
  default     = ""
}

variable "google_oauth_client_secret" {
  type        = string
  description = "Optional: Google OAuth 2.0 Web Client Secret to automatically seed into Secret Manager"
  sensitive   = true
  default     = ""
}
