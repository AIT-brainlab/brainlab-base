# Root Governance & Authorized Project Owners for ait-brainlab-mgmt

locals {
  authorized_owners = [
    "user:brainlab@ait.asia",
    "user:st121413@ait.asia",
    "user:akraradets@gmail.com",
  ]
}

# Grant roles/owner to the 3 root identities
resource "google_project_iam_member" "owners" {
  for_each = toset(local.authorized_owners)

  project = var.project_id
  role    = "roles/owner"
  member  = each.key
}

# Dedicated Service Account for Automation & CI/CD
resource "google_service_account" "mgmt_automation_sa" {
  account_id   = "brainlab-mgmt-automation"
  display_name = "Brainlab Management Automation Service Account"
  description  = "Service account for DNS, Identity, and Cloud Run automation tasks"
}

# Grant DNS Admin to Automation Service Account
resource "google_project_iam_member" "sa_dns_admin" {
  project = var.project_id
  role    = "roles/dns.admin"
  member  = "serviceAccount:${google_service_account.mgmt_automation_sa.email}"
}
