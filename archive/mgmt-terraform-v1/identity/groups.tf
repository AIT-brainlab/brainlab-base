# ==========================================================
# 👥 LLDAP Group Definitions & POSIX GIDs
# ==========================================================

# 1. 👑 Admin: System & Lab Administrators (Grants Linux 'sudo' privileges)
resource "lldap_group" "admin" {
  display_name = "admin"
}

resource "lldap_group_attribute_assignment" "admin_gid" {
  group_id     = lldap_group.admin.id
  attribute_id = "gidnumber"
  value        = ["10000"]
}

# 2. 👥 Member: Base group assigned to all active lab members
resource "lldap_group" "member" {
  display_name = "member"
}

resource "lldap_group_attribute_assignment" "member_gid" {
  group_id     = lldap_group.member.id
  attribute_id = "gidnumber"
  value        = ["10001"]
}

# 3. 🎓 Student: Active AIT students (Authenticates via @ait.asia)
resource "lldap_group" "student" {
  display_name = "student"
}

resource "lldap_group_attribute_assignment" "student_gid" {
  group_id     = lldap_group.student.id
  attribute_id = "gidnumber"
  value        = ["10002"]
}

# 4. 🏛️ Alumni: Graduated members & alumni (Authenticates via @gmail.com)
resource "lldap_group" "alumni" {
  display_name = "alumni"
}

resource "lldap_group_attribute_assignment" "alumni_gid" {
  group_id     = lldap_group.alumni.id
  attribute_id = "gidnumber"
  value        = ["10003"]
}
