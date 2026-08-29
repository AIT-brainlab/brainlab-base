output "project_owners" {
  description = "List of verified owner accounts on ait-brainlab-mgmt"
  value       = local.authorized_owners
}

output "terraform_service_account" {
  description = "Email of the management Terraform service account"
  value       = google_service_account.mgmt_terraform_sa.email
}
