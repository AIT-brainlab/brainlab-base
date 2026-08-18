# Linux SSSD Client Domain (`services/identity/sssd`)

## Overview
This directory contains the standardized **System Security Services Daemon (SSSD)** configuration for all physical Ubuntu Desktops, GPU compute servers (`la`, `tokyo`), and TrueNAS storage nodes (`cairo`).

SSSD integrates local Linux PAM/NSS authentication with our central **LLDAP** control plane over the encrypted **NetBird WireGuard mesh tunnel**.

---

## 📁 Directory Files

- [`sssd.conf.template`](sssd.conf.template): Standard production SSSD configuration.
- [`README.md`](README.md): Operational guide (this file).

---

## ⚙️ How It Works

```
 Ubuntu Login / SSH Terminal 
              │
              ▼
       PAM / NSS Stack
              │
              ▼
         Linux SSSD 
              │
              ▼ (Encrypted WireGuard Mesh: ldap://34.143.234.182:3890)
       LLDAP Directory (ait-brainlab-mgmt)
              │
              ├─► Verifies User Password / Credentials
              ├─► Returns Numeric POSIX UID (e.g. 121413) & GID (10001)
              ├─► Sets Home Directory Path (/mnt/HDD/home/<user>)
              └─► Grants 'sudo' access if user belongs to group 'admin'
```

---

## 🚀 Installation & Client Setup Runbook

### Step 1: Install SSSD & LDAP Utilities
```bash
sudo apt-get update
sudo apt-get install -y sssd sssd-tools libpam-sss libnss-sss ldap-utils
```

### Step 2: Deploy SSSD Configuration
```bash
# Retrieve LLDAP admin password from GCP Secret Manager
ADMIN_PW=$(gcloud secrets versions access latest --secret="lldap-admin-password" --project="ait-brainlab-mgmt")

# Copy template and substitute variables
sudo cp sssd.conf.template /etc/sssd/sssd.conf
sudo sed -i "s/<LLDAP_ADMIN_PASSWORD>/$ADMIN_PW/g" /etc/sssd/sssd.conf

# Enforce strict security permissions (SSSD will not start if permissions are loose)
sudo chown root:root /etc/sssd/sssd.conf
sudo chmod 600 /etc/sssd/sssd.conf
```

### Step 3: Configure PAM Home Directory Auto-Creation
```bash
sudo pam-auth-update --enable mkhomedir
```

### Step 4: Restart & Enable SSSD
```bash
sudo systemctl restart sssd
sudo systemctl enable sssd
sudo systemctl status sssd
```

---

## 🧪 Verification & Testing

Verify that SSSD can resolve directory users and POSIX attributes from LLDAP:

```bash
# Test user resolution
id st121413
# Expected output: uid=121413(st121413) gid=10001(member) groups=10001(member),10002(student)

id akraradet
# Expected output: uid=10001(akraradet) gid=10001(member) groups=10000(admin),10001(member),10003(alumni)

# Verify getent passwd
getent passwd st121413
# Expected output: st121413:*:121413:10001:Akraradet Sinsamersuk:/mnt/HDD/home/st121413:/bin/bash
```

---

## 🛡️ Offline Resilience
The configuration sets `cache_credentials = true`. If the campus proxy or internet connection drops, users who have logged into the physical desktop previously can **still log in offline using cached credentials**.
