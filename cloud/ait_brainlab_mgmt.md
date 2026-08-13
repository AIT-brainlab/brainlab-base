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

## 6. Ownership & Access Control

| Attribute / Role | Details |
| :--- | :--- |
| **GCP Project Name** | AIT Brainlab Management |
| **GCP Project ID** | `ait-brainlab-mgmt` |
| **Primary Region** | `asia-southeast1` (Bangkok / Singapore) |
| **Institutional Owner** | `brainlab@ait.asia` (`roles/owner`) |
| **Lead Admin & Billing Owner** | Akraradet Sinsamersuk (`089-122-2061`) |
| **Co-Infrastructure Lead** | Phue Pwint Thwe (`062-638-0858`) |

---

## 7. Infrastructure Implementation Tracking Checklist

Legend: 🔴 Not Started | 🟡 In Progress | 🟢 Completed | 🔵 Verified

### Phase 1: GCP Billing & Root Governance Setup
| Task ID | Task Description | Target Identity | Status | Notes / Output |
| :--- | :--- | :--- | :---: | :--- |
| `1.1` | Upgrade expired GCP Billing Account to Standard Billing in GCP Console | Akraradet | 🔴 | Requires credit/debit card verification |
| `1.2` | Assign `roles/owner` to `brainlab@ait.asia` across all projects | Akraradet | 🔴 | Guarantees non-expiring ownership |
| `1.3` | Confirm `ait-brainlab-mgmt` is linked to permanent active billing account | Akraradet | 🔴 | Protects Cloud DNS from downtime |

### Phase 2: Cloud DNS Verification & Delegation
| Task ID | Task Description | Target Identity | Status | Notes / Output |
| :--- | :--- | :--- | :---: | :--- |
| `2.1` | Verify Cloud DNS Managed Zone 1: `brain.cs.ait.ac.th` | Phue Pwint Thwe | 🔴 | Zone active in `ait-brainlab-mgmt` |
| `2.2` | Verify Cloud DNS Managed Zone 2: `dpi.ait.ac.th` | Phue Pwint Thwe | 🔴 | Zone active in `ait-brainlab-mgmt` |
| `2.3` | Test public DNS resolution via `dig brain.cs.ait.ac.th +short` | Phue Pwint Thwe | 🔴 | Verify NS record delegation |

### Phase 3: NetBird Zero-Trust Mesh VPN Deployment
| Task ID | Task Description | Target Identity | Status | Notes / Output |
| :--- | :--- | :--- | :---: | :--- |
| `3.1` | Create NetBird Cloud account at `app.netbird.io` via `brainlab@ait.asia` | Akraradet | 🔴 | Free Tier (up to 100 devices) |
| `3.2` | Configure Google OAuth2 SSO integration in NetBird dashboard | Akraradet | 🔴 | Enables 1-click Google login |
| `3.3` | Send NetBird invitations to lab members (`@ait.asia` & `@gmail.com`) | Akraradet | 🔴 | Invite members by email |
| `3.4` | Install NetBird agent on local compute nodes and NAS (`cairo`) | Phue Pwint Thwe | 🔴 | `netbird up --key <setup-key>` |
| `3.5` | Verify ping and WireGuard mesh connectivity across all nodes | Whole Team | 🔴 | Test ping across NetBird IPs |

### Phase 4: Central User Auth & LDAP Directory (`lldap`)
| Task ID | Task Description | Target Identity | Status | Notes / Output |
| :--- | :--- | :--- | :---: | :--- |
| `4.1` | Deploy `lldap` container (Cloud Run Serverless or `e2-micro` VM) | Phue Pwint Thwe | 🔴 | Config Base DN: `dc=brain,dc=cs,dc=ait,dc=ac,dc=th` |
| `4.2` | Create user entries in `lldap` mapping `@ait.asia`/`@gmail.com` to UIDs | Phue Pwint Thwe | 🔴 | Assign Unix usernames (e.g. `akraradet`) |
| `4.3` | Configure `sssd` / `pam_ldap` on local Linux compute nodes & NAS (`cairo`)| Phue Pwint Thwe | 🔴 | Point to LDAP port `:389` |
| `4.4` | Test `getent passwd` and NFS home directory permissions (`/home/user`) | Phue Pwint Thwe | 🔴 | Verify UID mapping on NAS |

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
