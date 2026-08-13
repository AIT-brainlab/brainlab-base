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
