# Core Identity Service: `lldap` (`mgmt/services/identity`)

## 1. Executive Overview

`lldap` (Rust Lightweight LDAP) is the central authorization and POSIX attribute directory for **AIT Brainlab**. It bridges Google OAuth2 Single Sign-On with numeric Unix POSIX permissions on TrueNAS NFS storage (`cairo:/mnt/HDD/home`) and Linux compute nodes.

---

## 2. Key Architecture Principles

1. **Strict AuthN vs. AuthZ Separation**:
   - **Authentication (AuthN)**: Handled **100% by Google OAuth2**. Google manages university credentials, passwords, 2FA, password resets, and graduation lifecycles. Supports `@ait.asia`, `@ait.ac.th`, and approved alumni `@gmail.com`.
   - **Authorization & POSIX Directory (AuthZ)**: Handled **100% by LLDAP**. LLDAP acts as a **passwordless directory** mapping verified emails to Unix UIDs/GIDs and TrueNAS storage paths. **LLDAP holds NO user passwords.**

2. **2-Tier Zero-Compute Gatekeeping**:
   - **Stage 1 (Google)**: Validates institutional enrollment or approved personal Gmail.
   - **Stage 2 (LLDAP)**: Validates that the Admin has provisioned a POSIX profile.
   - **Fast-Denial (< 2ms)**: Unprovisioned users fail at Stage 2 without spawning Docker containers, consuming GPU/RAM, or touching TrueNAS disks.

3. **Multi-Email Binding to Single POSIX UID (Alumni Continuity)**:
   - A single POSIX user record (`username`, `UID: 1042`, `GID: 10001`, `/mnt/HDD/home/<username>/work`) can bind multiple authorized emails:
     - Primary: `stXXXXXX@ait.asia` (Student)
     - Linked: `user@gmail.com` (Alumni / Collaborator)
   - When a graduate stays on as an alumnus/researcher, the admin simply binds their `@gmail.com` to their existing `lldap` record. **Zero data migration or `chown` required on TrueNAS.**

4. **Zero Internal TLS Complexity (NetBird WireGuard Encryption)**:
   - Internal LDAP traffic (TrueNAS, SSSD, Ubuntu Desktop) travels over the **NetBird WireGuard encrypted mesh**.
   - Internal clients use plain `ldap://` on port `:3890` with `ldap_id_use_start_tls = false`.
   - Eliminates self-signed CA bundles and Python `ldap3` package hacks completely.

5. **Physical Ubuntu Desktop (CSIM Printer Station)**:
   - Authenticates via SSSD/PAM over LDAP to allow local desktop login, home directory mounting, and printing.

---

## 3. Quickstart Deployment

```bash
docker compose up -d
```
Access the admin portal at `http://<HOST_IP>:17170` (or `https://auth.brain.cs.ait.ac.th`).

---

## 4. Directory Schema & Attributes

| Attribute | Example Value | Description |
| :--- | :--- | :--- |
| **`id` / `uid`** | `akraradet` | Unix username |
| **`uidNumber`** | `1001` | Numeric POSIX User ID |
| **`gidNumber`** | `10001` | Primary Group ID (`students` / `alumni`) |
| **`mail`** | `st121413@ait.asia` | Primary student email |
| **`emails`** | `["st121413@ait.asia", "akraradets@gmail.com"]` | Linked Google OAuth identities |
| **`homeDirectory`** | `/mnt/HDD/home/akraradet` | NFS home directory path on `cairo` |

---

## 5. Client SSSD Configuration Template (`/etc/sssd/sssd.conf`)

```ini
[sssd]
config_file_version = 2
services = nss, pam
domains = default

[nss]
filter_groups = root
filter_users = root

[pam]

[domain/default]
id_provider = ldap
auth_provider = ldap
chpass_provider = ldap

# Connect over NetBird WireGuard mesh
ldap_uri = ldap://auth.brain.cs.ait.ac.th:3890
ldap_search_base = dc=brain,dc=cs,dc=ait,dc=ac,dc=th

# Network-level encryption via WireGuard (No internal cert issues)
ldap_id_use_start_tls = false
ldap_tls_reqcert = never

# Schema Mapping
ldap_user_object_class = posixAccount
ldap_user_name = uid
ldap_user_uid_number = uidNumber
ldap_user_gid_number = gidNumber
ldap_user_home_directory = homeDirectory
ldap_user_shell = loginShell

cache_credentials = true
entry_cache_timeout = 600
ldap_network_timeout = 3
```
