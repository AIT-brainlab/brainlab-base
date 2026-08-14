# Infrastructure Documentation: `ait-brainlab-mgmt`

## 1. Executive Summary & Purpose

The `ait-brainlab-mgmt` (or `brainlab-mgmt`) Google Cloud project serves as the management control plane for **AIT Brainlab** (50+ users).

It is designed to support lab members using their **existing `@ait.asia` and `@gmail.com` Google accounts** without requiring expensive custom Google Workspace enterprise licenses.

The solution is **ultra-lightweight, near-zero cost (~$0.45 to $7.45 / month total)** and delivers 3 core capabilities:
1. **NetBird Mesh VPN**: Uses NetBird Managed Cloud (`app.netbird.io`) for zero-trust WireGuard connectivity.
2. **Central User Auth & LDAP**: Google OAuth2 for web apps + `lldap` directory mapping `@ait.asia`/`@gmail.com` accounts to Unix UIDs for Linux SSSD and NFS NAS (`cairo:/mnt/HDD/home`).
3. **Cloud DNS**: Authoritative DNS resolution for `brain.cs.ait.ac.th` and `dpi.ait.ac.th`.

---

## 2. Multi-Account Identity Architecture

```
                       [ Lab Members: `@ait.asia` & `@gmail.com` ]
                                            │
                                            ▼
                       ┌──────────────────────────────────────────┐
                       │ Google OAuth2 ("Sign in with Google")    │
                       └────────────────────┬─────────────────────┘
                                            │
         ┌──────────────────────────────────┼──────────────────────────────────┐
         ▼                                  ▼                                  ▼
┌──────────────────────────┐   ┌──────────────────────────┐   ┌──────────────────────────┐
│ 1. NetBird Mesh VPN      │   │ 2. JupyterHub / Web Apps │   │ 3. Linux SSH & NAS Auth  │
│ - NetBird Cloud (Free)   │   │ - Google OIDC Auth       │   │ - `lldap` User Directory │
│ - Invite `@ait.asia` &   │   │ - Allowed Email List     │   │   (Serverless/Tiny VM)   │
│   `@gmail.com` emails    │   │   (`@ait.asia`, `@gmail`)│   │ - Port `:389` for SSSD   │
│ - Cost: $0.00/month      │   │ - Cost: $0.00/month      │   │ - Cost: ~$0.00 - $7/month│
└──────────────────────────┘   └──────────────────────────┘   └──────────────────────────┘
```

---

## 3. Detailed Component Breakdown & Cost Matrix

| Component | Implementation Technology | Hosting Model | Monthly Cost |
| :--- | :--- | :--- | :--- |
| **1. NetBird Mesh VPN** | NetBird Managed Cloud (`app.netbird.io`) | SaaS (Free Tier up to 100 devices) | **$0.00 / month** |
| **2. Web & JupyterHub Auth** | Google OIDC ("Sign in with Google") | Serverless OAuth2 | **$0.00 / month** |
| **3. Linux & NAS LDAP Auth** | `lldap` (Rust-based Lightweight LDAP) | GCP Cloud Run or Tiny VM | **~$0.00 - $7.00 / month** |
| **4. Cloud DNS** | GCP Cloud DNS Managed Zones | GCP Native API | **~$0.45 / month** |
| **TOTAL ESTIMATED COST** | | | **~$0.45 - $7.45 / month** |

---

## 4. How Member Authentication Works

### A. NetBird WireGuard Mesh VPN
- Members log into [`app.netbird.io`](https://app.netbird.io) using their existing `@ait.asia` or `@gmail.com` accounts.
- Management invites members via email in the NetBird dashboard.
- Zero server hosting required on GCP.

### B. Web Applications & JupyterHub
- Web services use Google OIDC (`oauthenticator.google`).
- Configured with an email whitelist accepting all `@ait.asia` users and explicitly approved `@gmail.com` members.

### C. Linux SSH & On-Prem NFS NAS (`cairo:/mnt/HDD/home`)
- Linux compute nodes and NAS (`cairo`) require Unix UIDs/GIDs for file permissions.
- **`lldap`** maintains a lightweight directory mapping each member's `@ait.asia`/`@gmail.com` email to a Unix username (e.g., `akraradet`) and numeric UID.
- Linux machines query `lldap` on port `:389` via SSSD/PAM.

---

## 5. Billing & Governance Model

- **Billing Owner**: Personally / Lab-managed by Akraradet Sinsamersuk & `brainlab@ait.asia`.
- **Strategic Rationale**: By leveraging free Google OAuth2, NetBird Cloud, and Cloud Run/lightweight compute, management costs are kept under **~$7.50/month**, ensuring core DNS (`brain.cs.ait.ac.th` & `dpi.ait.ac.th`) and auth **never experience downtime** due to grant cycles or center changes.

---

## 6. Project Access Control & Authorized Accounts

The `ait-brainlab-mgmt` GCP project is currently owned and managed by **3 authorized accounts**:

| Account Email | Account Type | GCP IAM Role Granted | Purpose & Rationale |
| :--- | :--- | :--- | :--- |
| **`brainlab@ait.asia`** | Shared Team Account | `Owner` (`roles/owner`) | **Institutional Primary Owner**: Non-expiring shared identity for the AIT Brainlab management team. |
| **`st121413@ait.asia`** | University Account | `Owner` (`roles/owner`) | **Lead Admin (Academic Identity)**: Akraradet Sinsamersuk's university account for daily administration. |
| **`akraradets@gmail.com`** | Personal Account | `Owner` (`roles/owner`) / `Billing Admin` | **Lead Admin (Personal & Billing Identity)**: Akraradet Sinsamersuk's billing owner identity for continuous payment backup. |

---

## 7. Master Implementation & On-Premise Migration Task Checklist

Legend: 🔴 Not Started | 🟡 In Progress | 🟢 Completed | 🔵 Verified

### Phase 1: GCP Billing & Root Governance Setup
| Task ID | Task Description                                                                                          | Target Identity                    | Status | Notes / Output                          |
| :------ | :-------------------------------------------------------------------------------------------------------- | :--------------------------------- | :----: | :-------------------------------------- |
| `1.1`   | Upgrade expired GCP Billing Account to Standard Billing in GCP Console                                    | Akraradet (`akraradets@gmail.com`) |   🔵   | Requires credit/debit card verification |
| `1.2`   | Confirm `roles/owner` is assigned to `brainlab@ait.asia`, `st121413@ait.asia`, and `akraradets@gmail.com` | Akraradet                          |   🔵   | Guarantees multi-account access safety  |
| `1.3`   | Confirm `ait-brainlab-mgmt` is linked to permanent active billing account                                 | Akraradet                          |   🔵   | Protects Cloud DNS from downtime        |

### Phase 2: DNS Migration (On-Premise DNS $\rightarrow$ GCP Cloud DNS)
| Task ID | Task Description                                                                 | Target Identity | Status | Notes / Output                       |
| :------ | :------------------------------------------------------------------------------- | :-------------- | :----: | :----------------------------------- |
| `2.1`   | Export active DNS records (A, CNAME, TXT) from on-premise DNS server             | Phue Pwint Thwe |   🔵   | Audit existing zone files            |
| `2.2`   | Replicate zone records in GCP Cloud DNS (`brain.cs.ait.ac.th` & `dpi.ait.ac.th`) | Phue Pwint Thwe |   🔵   | Managed zones in `ait-brainlab-mgmt` |
| `2.3`   | Submit GCP NS record updates to parent domain registrar (`cs.ait.ac.th`)         | Phue Pwint Thwe |   🔴   | Delegate NS authority to GCP         |
| `2.4`   | Test public DNS resolution via `dig brain.cs.ait.ac.th +short` & `dig @8.8.8.8`  | Phue Pwint Thwe |   🔴   | Verify dual resolution               |
| `2.5`   | Decommission on-premise local DNS server after TTL expiration                    | Phue Pwint Thwe |   🔴   | Safe shutdown after 24-48 hrs        |
**

Objective: Make MOSIP deployment lighter and faster  
Problem: 

MOSIP RDI is designed to set up the “MOSIP reference architecture” in an automated way. It removes the human-error thus reduce the time to deploy MOSIP cluster. Consequently, it helps smoothing MOSIP POC with countries.

On the other hand, R&D organizations who wants to use MOSIP has to either deploy 

MOSIP is being use in 2 setting (1) deploying in country and (2) deploying in research lab 

MOSIP RDI is optimized for deploying in country

Alan Turing and AIT align on the point that RDI is not applicable for research setting.

Alan Turing initiative is another deployment script that suited their needs.

  

While a separate deployment script solve the research lab problem, the consequent of this is maintainability. 

AIT approach is to build on top of the RDI, use RDI as an engine to deploy MOSIP cluster.

This approach of load the deployment logic to RDI where consistently maintain by MOSIP team and AIT configure the packing the system that (1) suited research needs (2) work out of the box 

Thus, we bridge the gap where the deployment is fast and maintainable by MOSIP

**
### Phase 3: NetBird Migration (Self-Hosted On-Prem $\rightarrow$ NetBird Cloud)
| Task ID | Task Description | Target Identity | Status | Notes / Output |
| :--- | :--- | :--- | :---: | :--- |
| `3.1` | Create NetBird Cloud account at `app.netbird.io` via `brainlab@ait.asia` | Akraradet | 🔴 | Free Tier (up to 100 devices) |
| `3.2` | Configure Google OAuth2 SSO integration in NetBird dashboard | Akraradet | 🔴 | Enables 1-click Google login |
| `3.3` | Send NetBird invitations to lab members (`@ait.asia` & `@gmail.com`) | Akraradet | 🔴 | Invite members by email |
| `3.4` | Re-key local compute nodes and NAS (`cairo`): `netbird down && netbird up --key <new-key>` | Phue Pwint Thwe | 🔴 | Re-connect nodes to NetBird Cloud |
| `3.5` | Verify ping and WireGuard mesh connectivity across all nodes on `app.netbird.io` | Whole Team | 🔴 | Test ping across NetBird IPs |
| `3.6` | Decommission on-premise NetBird server containers | Phue Pwint Thwe | 🔴 | Stop & remove old NetBird containers |

### Phase 4: LDAP Migration (On-Prem LDAP $\rightarrow$ Cloud `lldap`)
| Task ID | Task Description | Target Identity | Status | Notes / Output |
| :--- | :--- | :--- | :---: | :--- |
| `4.1` | Export user accounts, UIDs, and GIDs from on-premise LDAP server | Phue Pwint Thwe | 🔴 | Dump posixAccount attributes |
| `4.2` | Deploy `lldap` container (Cloud Run Serverless or `e2-micro` VM) | Phue Pwint Thwe | 🔴 | Base DN: `dc=brain,dc=cs,dc=ait,dc=ac,dc=th` |
| `4.3` | Import user entries in `lldap` aligning UIDs/GIDs with NAS (`cairo`) permissions | Phue Pwint Thwe | 🔴 | Preserves `/mnt/HDD/home` file owners |
| `4.4` | Update `/etc/sssd/sssd.conf` on compute nodes & NAS (`cairo`) pointing to `lldap` `:389` | Phue Pwint Thwe | 🔴 | Point to Cloud Run/VM `lldap` IP |
| `4.5` | Test `getent passwd <user>` and verify NFS home directory read/write access | Phue Pwint Thwe | 🔴 | Test SSH & file access on `cairo` |
| `4.6` | Decommission on-premise OpenLDAP server (`sudo systemctl stop slapd`) | Phue Pwint Thwe | 🔴 | Shut down old LDAP service |

### Phase 5: Web Services & JupyterHub Google OIDC Integration
| Task ID | Task Description | Target Identity | Status | Notes / Output |
| :--- | :--- | :--- | :---: | :--- |
| `5.1` | Create OAuth2 Client ID & Secret in `GCP Console > APIs & Services` | Akraradet | 🔴 | Web application credential |
| `5.2` | Configure JupyterHub `oauthenticator.google` with email whitelist | Akraradet | 🔴 | Allow `@ait.asia` + approved `@gmail.com` |
| `5.3` | Test "Sign in with Google" flow for JupyterHub users | Whole Team | 🔴 | Verify 1-click login |

### Phase 6: Google Cloud Research Grants & Credits Application
| Task ID | Task Description | Target Identity | Status | Notes / Output |
| :--- | :--- | :--- | :---: | :--- |
| `6.1` | Generate GCP cost estimate using GCP Pricing Calculator | Whole Team | 🔴 | Compute, storage, GPU budget |
| `6.2` | Submit Google Cloud Research Credits application ($5k Faculty / $1k PhD) | Whole Team | 🔴 | Submit at `edu.google.com/programs/research-credits/` |
| `6.3` | Submit TPU Research Cloud (TRC) application for free TPU access | Whole Team | 🔴 | Submit at `sites.research.google/trc/` |
| `6.4` | Redeem approved promo code in GCP Billing & link to research project | Akraradet | 🔴 | Link to `brainlab-res-*` project |
| `6.5` | Set budget alerts (50%, 80%, 90%, 100%) & Pub/Sub VM auto-shutdown | Akraradet | 🔴 | Safeguard against out-of-pocket charges |
