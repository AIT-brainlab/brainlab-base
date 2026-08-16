variable "project_id" {
  type        = string
  description = "GCP Project ID for Management Plane"
  default     = "ait-brainlab-mgmt"
}

variable "region" {
  type        = string
  description = "GCP Region for management resources"
  default     = "asia-southeast1" # Singapore
}

variable "onprem_la_ip" {
  type        = string
  description = "Public IP address of on-premise compute node (la.cs.ait.ac.th)"
  default     = "192.41.170.85"
}

variable "onprem_tokyo_ip" {
  type        = string
  description = "Public IP address of on-premise service node (tokyo.cs.ait.ac.th)"
  default     = "192.41.170.85"
}

variable "alert_email" {
  type        = string
  description = "Primary institutional email for budget and downtime alerts"
  default     = "brainlab@ait.asia"
}
