# Researcher & Student Onboarding Runbook

## Overview
This Standard Operating Procedure (SOP) guides the Service Admin and Infrastructure Admin through onboarding a new member to AIT Brainlab.

---

## 📋 Onboarding Checklist

### Step 1: Collect Member Information
- Full Name
- Academic Email (`@ait.asia` / `@ait.ac.th`) and Personal Email (`@gmail.com`)
- Desired Unix Username (e.g. `firstnamel`)
- Research Advisor / PI Name
- Expected Duration & Project Topic

---

### Step 2: Create User Directory Account (`lldap` / LDAP)
1. Log into `lldap` admin interface at `https://auth.brain.cs.ait.ac.th` (or port `:17170`).
2. Create user with:
   - **Username**: `firstnamel`
   - **Email**: `user@ait.asia`
   - **UID/GID**: Automatically generated or assigned next sequential ID (e.g., `1042`).
   - **Groups**: Add to `students` or `researchers` group.

---

### Step 3: Initialize NAS Home Directory (`cairo`)
On `cairo` or via SSH:
```bash
sudo mkdir -p /mnt/HDD/home/<username>/work
sudo mkdir -p /mnt/HDD/home/<username>/.ssh
sudo chown -R <UID>:<GID> /mnt/HDD/home/<username>
sudo chmod 700 /mnt/HDD/home/<username>/.ssh
```

---

### Step 4: NetBird VPN Mesh Invitation
1. Go to [`app.netbird.io`](https://app.netbird.io) $\rightarrow$ **Users**.
2. Click **Invite User** and enter member's email (`@ait.asia`).
3. Send NetBird installation link to the member.

---

### Step 5: JupyterHub Access Confirmation
1. User navigates to `https://la.cs.ait.ac.th` (or `https://hub.brain.cs.ait.ac.th`).
2. Log in using assigned credentials or "Sign in with Google".
3. Verify spawner boots with allocated GPU and `/home/<username>/work` is writable.
