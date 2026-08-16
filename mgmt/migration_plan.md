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

## 5. Phase 8: Production Cutover & Legacy Decommissioning (DNS Cutoff)

Only after Phases 4, 5, 6, and 7 are 100% verified in parallel:

### Step-by-Step Cutover Execution
1. **Cutover DNS via Terraform**:
   - Open `mgmt/terraform/dns/brainlab.tf` and update `authen` and `netbird` to the Cloud VM Static IP (`34.143.234.182`).
   - Run `terraform apply` in `mgmt/terraform/dns/`.
2. **Enable Production Domain SSL in Traefik**:
   - Update `mgmt/terraform/vm/templates/docker-compose.yml.tftpl` router rules to accept production hostnames:
     ```yaml
     - "traefik.http.routers.lldap.rule=Host(`authen.brain.cs.ait.ac.th`) || Host(`authen2.brain.cs.ait.ac.th`)"
     - "traefik.http.routers.netbird.rule=Host(`netbird.brain.cs.ait.ac.th`) || Host(`netbird2.brain.cs.ait.ac.th`)"
     ```
   - Run `terraform apply` in `mgmt/terraform/vm/`. Traefik automatically acquires Let's Encrypt production certificates in **< 10 seconds**!
3. **Re-point Physical Compute & Storage Nodes**:
   - Update `/etc/sssd/sssd.conf` on `la`, `tokyo`, and `cairo` to query `lldap:3890` over the NetBird mesh.
   - Restart SSSD: `sudo systemctl restart sssd`.
4. **Enroll Physical Servers in New NetBird Mesh**:
   - Run `sudo netbird up --management-url https://netbird.brain.cs.ait.ac.th --key <KEY>`.
5. **Decommission Legacy On-Prem Services**:
   - Stop old OpenLDAP: `sudo systemctl stop slapd && sudo systemctl disable slapd`.
   - Stop legacy NetBird containers on `192.41.170.39`.
