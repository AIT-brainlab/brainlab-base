# ==========================================================
# 👤 LLDAP User Directory, POSIX Attributes & Group Memberships
# ==========================================================
# 🔒 INVARIANT: ZERO PASSWORDS STORED FOR HUMANS IN LLDAP
# - All human authentication & 2FA is delegated 100% to Google OAuth2 SSO.
# - LLDAP stores NO user passwords for web services or lab members.
# - The ONLY account with a password in LLDAP is the 'admin' service user,
#   whose credential lives securely in GCP Secret Manager ('lldap-admin-password').
# ==========================================================

locals {
  # Lookup map linking group names to their respective LLDAP Group IDs
  group_name_to_id = {
    "admin"   = lldap_group.admin.id
    "member"  = lldap_group.member.id
    "student" = lldap_group.student.id
    "alumni"  = lldap_group.alumni.id
  }

  # ==========================================================
  # 📋 Lab Members Directory (Single Source of Truth)
  #
  # Explicit POSIX Attributes:
  # - 'uid': Numeric Unix UID (ensures TrueNAS file ownership matches)
  # - 'gid': Primary Unix GID (10000 for admins, 10001 for lab members)
  # - 'home': Home directory on TrueNAS NFS (/mnt/HDD/home/<user>)
  # - 'shell': User login shell (/bin/bash)
  # ==========================================================
  users = {
    # 1. Institutional Lab Account
    "brainlab" = {
      email      = "brainlab@ait.asia"
      first_name = "AIT"
      last_name  = "Brainlab"
      uid        = 10000
      gid        = 10000
      home       = "/mnt/HDD/home/brainlab"
      shell      = "/bin/bash"
      groups     = ["admin", "member"]
    },

    # 2. Lead Admin (Alumni / Personal Billing Owner)
    "akraradet" = {
      email      = "akraradets@gmail.com"
      first_name = "Akraradet"
      last_name  = "Sinsamersuk"
      uid        = 10001
      gid        = 10001
      home       = "/mnt/HDD/home/akraradet"
      shell      = "/bin/bash"
      groups     = ["admin", "member", "alumni"]
    },

    # 3. System Administrator (Alumni)
    "phue" = {
      email      = "phuepwintthwe@ait.asia"
      first_name = "Phue Pwint"
      last_name  = "Thwe"
      uid        = 10002
      gid        = 10001
      home       = "/mnt/HDD/home/phue"
      shell      = "/bin/bash"
      groups     = ["admin", "member", "alumni"]
    },

    # 4. Student Researcher Account
    "st121413" = {
      email      = "st121413@ait.asia"
      first_name = "Akraradet"
      last_name  = "Sinsamersuk"
      uid        = 121413
      gid        = 10001
      home       = "/mnt/HDD/home/st121413"
      shell      = "/bin/bash"
      groups     = ["member", "student"]
    }
  }
}

# 1. Declarative LLDAP User Management (100% HTTPS GraphQL, Passwordless)
resource "lldap_user" "users" {
  for_each = local.users

  username   = each.key
  email      = each.value.email
  first_name = each.value.first_name
  last_name  = each.value.last_name
}

# 2. Declarative Group Memberships
resource "lldap_user_memberships" "user_groups" {
  for_each = local.users

  user_id = lldap_user.users[each.key].id
  group_ids = [
    for group_name in each.value.groups :
    tostring(local.group_name_to_id[group_name])
  ]
}

# 3. Forced POSIX Attribute: uidnumber
resource "lldap_user_attribute_assignment" "user_uid_numbers" {
  for_each     = local.users
  user_id      = lldap_user.users[each.key].id
  attribute_id = "uidnumber"
  value        = [tostring(each.value.uid)]
}

# 4. Forced POSIX Attribute: gidnumber
resource "lldap_user_attribute_assignment" "user_gid_numbers" {
  for_each     = local.users
  user_id      = lldap_user.users[each.key].id
  attribute_id = "gidnumber"
  value        = [tostring(each.value.gid)]
}

# 5. Forced POSIX Attribute: homedirectory
resource "lldap_user_attribute_assignment" "user_home_directories" {
  for_each     = local.users
  user_id      = lldap_user.users[each.key].id
  attribute_id = "homedirectory"
  value        = [each.value.home]
}

# 6. Forced POSIX Attribute: loginshell
resource "lldap_user_attribute_assignment" "user_login_shells" {
  for_each     = local.users
  user_id      = lldap_user.users[each.key].id
  attribute_id = "loginshell"
  value        = [each.value.shell]
}
