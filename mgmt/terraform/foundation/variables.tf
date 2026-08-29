variable "project_id" {
  type        = string
  description = "GCP Project ID for Management Plane"
  default     = "ait-brainlab-mgmt"
}

variable "region" {
  type        = string
  description = "GCP Region for Management Plane resources"
  default     = "asia-southeast1"
}

variable "google_oauth_client_id" {
  type        = string
  description = "Google OAuth 2.0 Web Client ID to seed into Secret Manager"
  default     = ""
}

variable "google_oauth_client_secret" {
  type        = string
  description = "Google OAuth 2.0 Web Client Secret to seed into Secret Manager"
  sensitive   = true
  default     = ""
}
