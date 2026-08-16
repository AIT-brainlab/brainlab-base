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
    prefix = "iam"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Required GCP APIs for IAM
resource "google_project_service" "iam_apis" {
  for_each = toset([
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
  ])

  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}

locals {
  authorized_owners = [
    "user:brainlab@ait.asia",
    "user:st121413@ait.asia",
    "user:akraradets@gmail.com",
  ]
}

# Project Owners
resource "google_project_iam_member" "owners" {
  for_each = toset(local.authorized_owners)

  project    = var.project_id
  role       = "roles/owner"
  member     = each.key
  depends_on = [google_project_service.iam_apis]
}

# Dedicated Service Account for Terraform CI/CD & Automation
resource "google_service_account" "mgmt_terraform_sa" {
  account_id   = "brainlab-mgmt-terraform"
  display_name = "Brainlab Management Terraform Service Account"
  description  = "Service account used by Terraform and CI/CD pipelines to manage infrastructure"
  depends_on   = [google_project_service.iam_apis]
}

# Grant DNS Admin to Terraform Service Account
resource "google_project_iam_member" "sa_dns_admin" {
  project = var.project_id
  role    = "roles/dns.admin"
  member  = "serviceAccount:${google_service_account.mgmt_terraform_sa.email}"
}
