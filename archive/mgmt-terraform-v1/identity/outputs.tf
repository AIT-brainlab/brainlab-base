output "groups" {
  description = "List of created LLDAP group names and IDs"
  value = {
    for name, id in local.group_name_to_id : name => id
  }
}

output "users" {
  description = "Map of active managed LLDAP users"
  value = {
    for k, v in lldap_user.users : k => {
      id    = v.id
      email = v.email
    }
  }
}

output "total_users_count" {
  description = "Total number of declarative users provisioned in LLDAP"
  value       = length(local.users)
}

output "total_groups_count" {
  description = "Total number of LLDAP groups managed in Terraform"
  value       = length(local.group_name_to_id)
}
