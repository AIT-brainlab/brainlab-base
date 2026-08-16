# On-Premise to Cloud Zero-Downtime Migration Plan (`mgmt/`)

This document details the step-by-step zero-downtime migration strategy for transitioning AIT Brainlab's core infrastructure services from **local on-premise servers** to **GCP (`ait-brainlab-mgmt`) & Cloud Services**.

---

## 1. Migration Overview & Target Matrix

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                                ON-PREMISE TO GCP MIGRATION                             │
└────────────────────────────────────────────────────────────────────────────────────────┘
                                           │
         ┌─────────────────────────────────┼─────────────────────────────────┐
         ▼                                 ▼                                 ▼
┌─────────────────────────┐       ┌─────────────────────────┐       ┌─────────────────────────┐
│     1. NETBIRD VPN      │       │         2. DNS          │       │      3. LDAP AUTH       │
├─────────────────────────┤       ├─────────────────────────┤       ├─────────────────────────┤
│ CURRENT: Local Server   │       │ CURRENT: Local DNS      │       │ CURRENT: On-Prem LDAP   │
│ TARGET: NetBird Cloud   │       │ TARGET: GCP Cloud DNS   │       │ TARGET: Cloud `lldap`   │
│ COST: $0.00/month       │       │ COST: ~$0.45/month      │       │ COST: ~$0.00-$7.00/mo   │
└─────────────────────────┘       └─────────────────────────┘       └─────────────────────────┘
```

---

## 2. Service 1: NetBird Migration (Local Server $\rightarrow$ NetBird Cloud)

### Objective
Migrate all lab devices and compute nodes from the local self-hosted NetBird server to **NetBird Managed Cloud** (`app.netbird.io`), eliminating local server maintenance and enabling 1-click Google Login for `@ait.asia` and `@gmail.com` members.

### Step-by-Step Execution
1. **Create NetBird Cloud Account**: Log into [`app.netbird.io`](https://app.netbird.io) via `brainlab@ait.asia` and enable Google SSO.
2. **Invite Members**: Add member emails (`@ait.asia` & `@gmail.com`).
3. **Re-key Nodes**:
   ```bash
   netbird down
   netbird up --management-url https://api.netbird.io --key <NEW_SETUP_KEY>
   ```
4. **Decommission Local Server**: Once all nodes are online in NetBird Cloud, stop local containers:
   ```bash
   docker stop netbird-management netbird-signal
   docker rm netbird-management netbird-signal
   ```

---

## 3. Service 2: DNS Migration (Local DNS $\rightarrow$ GCP Cloud DNS)

### Objective
Migrate domain resolution for `brain.cs.ait.ac.th` and `dpi.ait.ac.th` to **GCP Cloud DNS** in `ait-brainlab-mgmt` for 100% SLA uptime.

### Step-by-Step Execution
1. **Export Active Records**: Audit on-premise DNS zone files.
2. **Replicate in GCP**: Provision zones via `mgmt/terraform/` (`brain.cs.ait.ac.th` and `dpi.ait.ac.th`).
3. **Delegate Parent NS**: Submit the 4 Google Cloud DNS NS records to `cs.ait.ac.th` parent registrar.
4. **Verify Resolution**:
   ```bash
   dig @8.8.8.8 brain.cs.ait.ac.th +short
   dig @ns-cloud-a1.googledomains.com brain.cs.ait.ac.th +short
   ```
5. **Decommission Local DNS**: Safe shutdown after TTL expires (24-48 hrs).

---

## 4. Service 3: LDAP Migration (On-Prem LDAP $\rightarrow$ Cloud `lldap`)

### Objective
Migrate user directory authentication from on-premise LDAP to **`lldap`**, preserving existing Unix UIDs and GIDs so NFS home directory permissions on NAS (`cairo:/mnt/HDD/home`) remain 100% intact.

### Step-by-Step Execution
1. **Export UIDs/GIDs**:
   ```bash
   ldapsearch -x -b "dc=ldap,dc=brainlab" "(objectClass=posixAccount)" uid uidNumber gidNumber mail
   ```
2. **Deploy `lldap`**: Run container using `mgmt/services/identity/docker-compose.yml`.
3. **Import Users**: Create entries matching exact numeric UIDs (e.g. `akraradet` UID on `cairo`).
4. **Update SSSD**: Point `/etc/sssd/sssd.conf` on compute nodes to `lldap` port `:3890` or `:389`.
5. **Verify Access**:
   ```bash
   getent passwd <username>
   ls -la /mnt/HDD/home/<username>
   ```
6. **Decommission Slapd**: `sudo systemctl stop slapd && sudo systemctl disable slapd`.
