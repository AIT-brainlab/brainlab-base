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
│ CURRENT: On-Prem Server │       │ CURRENT: Local DNS      │       │ CURRENT: On-Prem LDAP   │
│ TARGET: Self-Hosted VM  │       │ TARGET: GCP Cloud DNS   │       │ TARGET: Cloud `lldap`   │
│ COST: $0.00 extra (VM)  │       │ COST: ~$0.45/month      │       │ COST: <$5.00/month (VM) │
└─────────────────────────┘       └─────────────────────────┘       └─────────────────────────┘
```

---

## 2. Service 1: NetBird Migration (Local Server $\rightarrow$ Unified Control VM)

### Objective
Migrate all lab devices and compute nodes to the **Self-Hosted NetBird** service co-hosted on the Unified Management VM, eliminating device limits and enabling 1-click Google Login for `@ait.asia` and `@gmail.com` members.

### Step-by-Step Execution
1. **Deploy NetBird on Control VM**: Launch Docker Compose stack on Management VM (`ait-brainlab-mgmt`).
2. **Fetch Setup Key**:
   ```bash
   SETUP_KEY=$(gcloud secrets versions access latest --secret="netbird-setup-key" --project="ait-brainlab-mgmt")
   ```
3. **Re-key Nodes**:
   ```bash
   netbird down
   netbird up --management-url https://netbird.brain.cs.ait.ac.th --key "$SETUP_KEY"
   ```
4. **Decommission Old NetBird Server**: Once all nodes are online on the new control plane, safely decommission legacy containers.

---

## 3. Service 2: DNS Migration (Local DNS $\rightarrow$ GCP Cloud DNS)

### Objective
Migrate domain resolution for `brain.cs.ait.ac.th` and `dpi.ait.ac.th` to **Google Cloud DNS** in `ait-brainlab-mgmt` for 100% SLA uptime.

### Step-by-Step Execution
1. **Provision Zones & Records**: Deploy via `mgmt/terraform/dns/` (protected with `lifecycle.prevent_destroy = true`).
2. **Delegate Parent NS**: Submit the 4 Google Cloud DNS NS records to `cs.ait.ac.th` parent registrar.
3. **Verify Resolution**:
   ```bash
   cd mgmt/terraform/dns
   bash check_delegation.sh
   ```
4. **Decommission Local DNS**: Safe shutdown after TTL expires.

---

## 4. Service 3: LDAP Migration (On-Prem LDAP $\rightarrow$ Cloud `lldap`)

### Objective
Migrate user directory authentication from on-premise OpenLDAP to **`lldap`** on the Management VM, preserving existing Unix UIDs and GIDs so NFS home directory permissions on NAS (`cairo:/mnt/HDD/home`) remain 100% intact.

### Step-by-Step Execution
1. **Export UIDs/GIDs**:
   ```bash
   ldapsearch -x -b "dc=brain,dc=cs,dc=ait,dc=ac,dc=th" "(objectClass=posixAccount)" uid uidNumber gidNumber mail
   ```
2. **Deploy `lldap`**: Run container using `mgmt/services/identity/docker-compose.yml` on the Management VM.
3. **Import Users**: Create entries matching exact numeric UIDs (e.g. `akraradet` UID on `cairo`).
4. **Update SSSD**: Point `/etc/sssd/sssd.conf` on compute nodes to `lldap:3890` over the NetBird WireGuard mesh tunnel.
5. **Verify Access**:
   ```bash
   getent passwd <username>
   ls -la /mnt/HDD/home/<username>/work
   ```
6. **Decommission Legacy Slapd**: `sudo systemctl stop slapd && sudo systemctl disable slapd`.
