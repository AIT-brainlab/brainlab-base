terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "ait-brainlab-mgmt-tfstate"
    prefix = "dns"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Ensure Cloud DNS API is enabled
resource "google_project_service" "dns_api" {
  project            = var.project_id
  service            = "dns.googleapis.com"
  disable_on_destroy = false
}
