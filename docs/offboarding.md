# Member Offboarding & Data Archiving Runbook

## Overview
This runbook defines the process for archiving user data and revoking access upon graduation or project completion.

---

## 📋 Offboarding Steps

### Step 1: Data Preservation & Archive
1. Notify the user 30 days prior to account deactivation to transfer personal files.
2. Compress and archive the user's project work on TrueNAS:
   ```bash
   sudo tar -czvf /mnt/HDD/archive/<username>_$(date +%Y%m%d).tar.gz /mnt/HDD/home/<username>/work
   ```

---

### Step 2: Revoke VPN Access
1. Log into [`app.netbird.io`](https://app.netbird.io) $\rightarrow$ **Users**.
2. Remove the user or revoke their personal device tokens.

---

### Step 3: Deactivate Directory Account
1. In `lldap` admin console $\rightarrow$ Disable user login or delete from active research groups.
2. If using OpenLDAP:
   ```bash
   ldapdelete -x -D "cn=admin,dc=ldap,dc=brainlab" -W "uid=<username>,ou=people,dc=ldap,dc=brainlab"
   ```

---

### Step 4: Reclaim Resources
1. Remove any persistent Jupyter single-user containers:
   ```bash
   docker ps -a | grep jupyter-<username>
   docker rm -f jupyter-<username>
   ```
2. Free up GPU allocations if statically mapped in `jupyterhub_config.py`.
