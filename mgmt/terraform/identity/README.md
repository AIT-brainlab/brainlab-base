# Identity-as-Code Module (`mgmt/terraform/identity`)

This Terraform module implements **100% Stateless Identity-as-Code** for AIT Brainlab using [`LLDAP`](https://github.com/lldap/lldap) and the [`tasansga/lldap`](https://registry.terraform.io/providers/tasansga/lldap/latest) Terraform provider.

---

## 🎯 Architecture & Governance Invariants

1. **🔐 ZERO Passwords for Humans in LLDAP**: LLDAP stores **NO user passwords** for human lab members (`brainlab`, `akraradet`, `phue`, `st121413`). All human authentication and 2FA are handled 100% by **Google OAuth2 SSO** (`@ait.asia`, `@ait.ac.th`, approved alumni `@gmail.com`).
2. **👑 Admin-Only Password**: The **ONLY** account with an LDAP password is the administrative service bind user: **`admin`**. Its password is created once and stored exclusively in **GCP Secret Manager** (`lldap-admin-password`).
3. **📁 AuthZ (Passwordless POSIX Directory)**: LLDAP acts strictly as an authorization and POSIX mapping directory (mapping emails to Unix UIDs/GIDs and TrueNAS storage paths).
4. **🔗 Multi-Email Binding**: A single POSIX user account can bind multiple authorized emails (`@ait.asia` + `@gmail.com`) for seamless alumni continuation without data migration.
5. **⚡ 100% Stateless GitOps**: If the management VM is destroyed, running `terraform apply` in this module re-creates all users and groups in **< 3 seconds**.

---

## 📁 File Structure

| File | Description |
| :--- | :--- |
| [`main.tf`](main.tf) | Terraform & Provider definitions (`tasansga/lldap`, `google`), Secret Manager data lookup, and GCS remote backend (`gs://ait-brainlab-mgmt-tfstate/identity`). |
| [`groups.tf`](groups.tf) | Declarative group definitions (`admin` [10000], `member` [10001], `student` [10002], `alumni` [10003]). |
| [`users.tf`](users.tf) | **Single Source of Truth** for all lab members, emails, names, forced POSIX attributes (`uid`, `gid`, `home`, `shell`), and group memberships. |
| [`variables.tf`](variables.tf) | Module input variables and defaults. |
| [`outputs.tf`](outputs.tf) | Outputs summary of provisioned users, groups, and member counts. |
| [`check_identity.sh`](check_identity.sh) | Automated health check script verifying LLDAP API and Secret Manager integration. |
| [`test_login.py`](test_login.py) | Interactive CLI credential tester and user inspector. |
| [`import_ldif_to_tf.py`](import_ldif_to_tf.py) | Python helper to convert legacy on-premise OpenLDAP `.ldif` dumps into `users.tf` entries. |

---

## 🚀 Quick Start Deployment

### 1. Verify Connectivity
Before running Terraform, ensure the LLDAP endpoint and Secret Manager are healthy:

```bash
cd mgmt/terraform/identity
bash check_identity.sh
```

### 2. Initialize Terraform
```bash
terraform init
```

### 3. Review Plan & Apply
```bash
terraform plan
terraform apply
```

---

## ➕ How to Manage Lab Members

### Adding a New Student or Researcher
Open [`users.tf`](users.tf) and add a new entry to the `local.users` map:

```hcl
"st123456" = {
  email      = "st123456@ait.asia"
  first_name = "Jane"
  last_name  = "Doe"
  uid        = 123456
  gid        = 10001
  home       = "/mnt/HDD/home/st123456"
  shell      = "/bin/bash"
  groups     = ["member", "student"]
},
```

Then run:
```bash
terraform apply
```

### Offboarding / Graduating to Alumni
When a student graduates, update their groups to `alumni` and optionally bind their personal `@gmail.com`:

```hcl
"st123456" = {
  email      = "jane.doe@gmail.com"
  first_name = "Jane"
  last_name  = "Doe"
  uid        = 123456
  gid        = 10001
  home       = "/mnt/HDD/home/st123456"
  shell      = "/bin/bash"
  groups     = ["member", "alumni"]
},
```

---

## 🔄 Migrating Legacy Users from On-Prem OpenLDAP

If you have an exported LDIF dump from the legacy on-premise LDAP server:

```bash
# 1. Export from on-premise server
ldapsearch -x -H "ldap://192.41.170.39" -b "dc=brain,dc=cs,dc=ait,dc=ac,dc=th" \
  "(objectClass=posixAccount)" uid mail givenName sn > onprem_users.ldif

# 2. Convert to Terraform format
python3 import_ldif_to_tf.py onprem_users.ldif > imported_users.tf

# 3. Merge into users.tf and apply
terraform apply
```
