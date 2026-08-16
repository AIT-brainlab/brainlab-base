variable "project_id" {
  type        = string
  description = "GCP Project ID for the research workload (e.g. brainlab-res-llm)"
}

variable "region" {
  type        = string
  description = "GCP Region"
  default     = "asia-southeast1"
}

variable "zone" {
  type        = string
  description = "GCP Zone for compute instance"
  default     = "asia-southeast1-a"
}

variable "researcher_name" {
  type        = string
  description = "Name or topic identifier for the compute resource"
  default     = "default"
}

variable "create_gpu_instance" {
  type        = bool
  description = "Whether to provision a GPU instance"
  default     = false
}

variable "machine_type" {
  type        = string
  description = "Machine type for VM"
  default     = "g2-standard-4" # NVIDIA L4 GPU instance type
}

variable "gpu_type" {
  type        = string
  description = "Accelerator type"
  default     = "nvidia-l4"
}

variable "gpu_count" {
  type        = number
  description = "Number of GPUs"
  default     = 1
}

variable "use_spot_vm" {
  type        = bool
  description = "Use Spot VM (60-91% cheaper for research workloads)"
  default     = true
}

variable "alert_email" {
  type        = string
  description = "Admin email for budget threshold alerts"
  default     = "brainlab@ait.asia"
}
