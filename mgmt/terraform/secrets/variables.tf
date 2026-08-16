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
