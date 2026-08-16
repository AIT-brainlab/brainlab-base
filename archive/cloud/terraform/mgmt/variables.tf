variable "project_id" {
  type        = string
  description = "GCP Project ID for Management Plane (e.g. ait-brainlab-mgmt)"
  default     = "ait-brainlab-mgmt"
}

variable "region" {
  type        = string
  description = "GCP Region for cloud resources"
  default     = "asia-southeast1" # Singapore (closest to Thailand)
}
