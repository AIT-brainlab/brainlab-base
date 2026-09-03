# AIT Brainlab Identity-as-Code (GitOps)

## 📌 Overview
This directory serves as the **single source of truth** for all AIT Brainlab members, POSIX user accounts, numeric UIDs/GIDs, home paths, and group memberships.

Identity is **100% decoupled from Terraform** to eliminate chicken-and-egg dependencies and fragile third-party provider drift. Changes are declared in [`members.yaml`](members.yaml) and synchronized to LLDAP via [`sync_users.py`](sync_users.py).

---

## 🏗️ Architecture & Core Principles

```
                  ┌──────────────────────────────┐
                  │ 👥 members.yaml (Git Source) │
                  └──────────────┬───────────────┘
                                 │
                   python3 sync_users.py --apply
                                 │
                                 ▼
                  ┌──────────────────────────────┐
                  │ 👤 LLDAP GraphQL Engine      │
                  │  (https://ldap.brain...)     │
                  └──────────────┬───────────────┘
                                 │
     ┌───────────────────────────┼───────────────────────────┐
     │                           │                           │
     ▼                           ▼                           ▼
┌──────────────┐          ┌──────────────┐          ┌──────────────┐
│  Linux SSSD  │          │  TrueNAS NFS │          │  JupyterHub  │
│ (la, tokyo)  │          │ (/mnt/pool-1)│          │ (DockerSpawn)│
└──────────────┘          └──────────────┘          └──────────────┘
```

1. **AuthN vs. AuthZ Separation**:
   - **Authentication (AuthN)** is 100% handled by **Google OAuth2 SSO**. LLDAP stores **NO passwords** for human users (`NULL` password hashes in database).
   - **Authorization & POSIX (AuthZ)** is handled by LLDAP, mapping authenticated emails (`@ait.asia` or `@gmail.com`) to numeric Unix UIDs and home directories.
2. **Multi-Email Binding & Service Matrix**:
   - A single POSIX user account (`akraradets`, UID `121413`) can declare a `primary_email` and optional `secondary_emails`.
   - **`primary_email` (Institutional/Authoritative)**: Used for heavy GPU compute access (**JupyterHub** on `la`) and primary POSIX mapping. JupyterHub authorizes strictly against `primary_email` to ensure automatic revocation of compute resources when an institutional account is deactivated upon graduation.
   - **`secondary_emails` (Personal/Alumni)**: Used for lightweight service identity mapping (such as **Web Print** CSIM student quota resolution and NetBird VPN mesh alumni tracking) and POSIX UID preservation without file copying or `chown`.
3. **Simplified Group Structure**:
   - **`brainlab`**: Primary group for all active researchers, students, faculty, and alumni.
   - **`admin`**: Strictly for the master lab service account (`bci` / `brainlab@ait.asia`).

---

## 👥 Members Schema (`members.yaml`)

```yaml
groups:
  - name: admin
    display_name: "Administrators"
  - name: brainlab
    display_name: "Brainlab Members"

members:
  - username: akraradets
    display_name: "Akraradet Sinsamersuk"
    primary_email: st121413@ait.asia
    secondary_emails:
      - akraradets@gmail.com             # Multi-Email Binding for alumni access
    uid: 121413                         # Matches TrueNAS numeric POSIX UID
    gid: 2002                          # Primary GID (brainlab)
    home_directory: /mnt/pool-1/home/akraradets
    login_shell: /bin/bash
    groups: [brainlab]
```

---

## 🚀 How to Add or Update a Member

### Option A: Automatic Synchronization (GitOps CI/CD)
1. **Edit [`members.yaml`](members.yaml)** and push to the `main` branch.
2. The GitHub Action workflow [`.github/workflows/sync_identity.yml`](../../.github/workflows/sync_identity.yml) automatically joins the NetBird WireGuard mesh and applies changes to LLDAP in real-time.

### Option B: Local / Manual Synchronization
1. **Connect to NetBird Mesh** (Required to bypass Traefik's mesh-only allowlist on `ldap.brain.cs.ait.ac.th`):
   ```bash
   netbird up
   ```
2. **Preview Changes (Dry Run)**:
   ```bash
   ./mgmt/identity/sync_users.py
   ```
   *(Displays exact field-level diffs, group additions/removals, and orphaned accounts).*
3. **Apply Changes to Live LLDAP**:
   ```bash
   ./mgmt/identity/sync_users.py --apply
   ```

---

## 🔐 Service Account for Queries (`ldapservice`)

Downstream systems (Linux SSSD on compute nodes, TrueNAS, and JupyterHub) need an account to query user records without storing human credentials.

### Why It's Created in GitOps (Not Terraform)
Creating service accounts in Terraform introduces a circular dependency (Terraform attempting to connect to an application endpoint before the VM is running). `sync_users.py` handles this post-deployment cleanly.

### Service Account Details:
- **Username**: `ldapservice`
- **Role**: `lldap_strict_readonly` (built-in group giving search-only access; cannot modify anything)
- **Credential Storage**: Random 32-character password stored securely in **GCP Secret Manager** as `lldap-readonly-password`.

### How Downstream Systems Consume It:
- **Linux SSSD (`/etc/sssd/sssd.conf`)**:
  ```ini
  [domain/brainlab]
  id_provider = ldap
  auth_provider = none
  ldap_uri = ldap://brainlab-mgmt-vm:3890
  ldap_search_base = dc=brain,dc=cs,dc=ait,dc=ac,dc=th
  ldap_default_bind_dn = uid=ldapservice,ou=people,dc=brain,dc=cs,dc=ait,dc=ac,dc=th
  ldap_default_authtok = <fetched-from-secret-manager>
  ldap_id_use_start_tls = false
  ```
- **Command-Line Query (`ldapsearch`)**:
  ```bash
  SERVICE_PW=$(gcloud secrets versions access latest --secret=lldap-readonly-password --project=ait-brainlab-mgmt)

  ldapsearch -x \
    -H ldap://brainlab-mgmt-vm:3890 \
    -D "uid=ldapservice,ou=people,dc=brain,dc=cs,dc=ait,dc=ac,dc=th" \
    -w "$SERVICE_PW" \
    -b "dc=brain,dc=cs,dc=ait,dc=ac,dc=th" \
    "(uid=akraradets)"
  ```
