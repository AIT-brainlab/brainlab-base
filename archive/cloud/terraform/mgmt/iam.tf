# Authorized Owners for ait-brainlab-mgmt Project

locals {
  authorized_owners = [
    "user:brainlab@ait.asia",
    "user:st121413@ait.asia",
    "user:akraradets@gmail.com",
  ]
}

resource "google_project_iam_member" "owners" {
  for_each = toset(local.authorized_owners)

  project = var.project_id
  role    = "roles/owner"
  member  = each.key
}
