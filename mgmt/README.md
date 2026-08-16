# Core Management Plane: `ait-brainlab-mgmt` (`mgmt/`)

## 1. Executive Summary & Purpose

The `ait-brainlab-mgmt` Google Cloud project and this `mgmt/` directory form the permanent **Core Management Plane** for **AIT Brainlab** (50+ members).

It is explicitly decoupled from research compute workloads and grant cycles. Designed to support lab members using their **existing `@ait.asia` and `@gmail.com` Google accounts** without expensive enterprise licenses, it delivers 3 critical core services for **~$0.45 to $7.45 / month total**:

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                        CORE MANAGEMENT CONTROL PLANE (`mgmt/`)                         │
└────────────────────────────────────────────────────────────────────────────────────────┘
                                            │
         ┌──────────────────────────────────┼──────────────────────────────────┐
         ▼                                  ▼                                  ▼
┌──────────────────────────┐   ┌──────────────────────────┐   ┌──────────────────────────┐
│  1. NETBIRD MESH VPN     │   │  2. IDENTITY & DIRECTORY │   │      3. CLOUD DNS        │
│  (`mgmt/services/vpn/`)  │   │(`mgmt/services/identity`)│   │  (`mgmt/services/dns/`)  │
├──────────────────────────┤   ├──────────────────────────┤   ├──────────────────────────┤
│ - Zero-trust WireGuard   │   │ - Rust `lldap` Directory │   │ - `brain.cs.ait.ac.th`   │
│ - Google OAuth2 SSO      │   │ - POSIX UIDs for NAS     │   │ - `dpi.ait.ac.th`        │
│ - Free SaaS (100 peers)  │   │ - Cloud Run / Tiny VM    │   │ - 100% SLA uptime        │
│ - Cost: $0.00/month      │   │ - Cost: ~$0.00 - $7.00/mo│   │ - Cost: ~$0.45/month     │
└──────────────────────────┘   └──────────────────────────┘   └──────────────────────────┘
```

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

## 3. Directory Layout

```
mgmt/
├── README.md                          # Architecture, governance & overview (this file)
├── checklist.md                       # Master Implementation & Migration Tracker (Phases 1–6)
├── migration_plan.md                  # Zero-downtime on-prem to cloud migration SOP
│
├── terraform/                         # Dedicated IaC for ait-brainlab-mgmt
│   ├── main.tf                        # GCP provider & required APIs
│   ├── dns.tf                         # Cloud DNS: brain.cs.ait.ac.th & dpi.ait.ac.th
│   ├── iam.tf                         # Project owner IAM bindings
│   ├── variables.tf
│   └── terraform.tfvars.example
│
└── services/                          # Core Service Configurations
    ├── dns/                           # Authoritative Cloud DNS & verification
    ├── identity/                      # lldap Docker Compose, POSIX schema, SSSD template
    └── vpn/                           # NetBird Managed Cloud & node onboarding
```

---

## 4. Root Governance & Authorized Accounts

The `ait-brainlab-mgmt` project is owned by **3 authorized accounts**:

| Authorized Account | Account Type | IAM Role | Governance Purpose |
| :--- | :--- | :--- | :--- |
| **`brainlab@ait.asia`** | Shared Team Account | `roles/owner` | **Institutional Owner**: Primary non-expiring shared identity for lab continuity. |
| **`st121413@ait.asia`** | University Account | `roles/owner` | **Lead Admin**: Akraradet Sinsamersuk's university identity for daily admin. |
| **`akraradets@gmail.com`** | Personal Account | `roles/owner` / `Billing Admin` | **Billing Owner**: Personal account ensuring backup payment & billing safety. |

---

## 5. Cost Breakdown & Budget Safeguards

| Service | Technology | Hosting Model | Monthly Cost |
| :--- | :--- | :--- | :--- |
| **NetBird Mesh VPN** | NetBird Managed Cloud | SaaS (Free Tier up to 100 devices) | **$0.00 / month** |
| **Google OIDC Auth** | Google Cloud APIs & Services | Serverless OAuth2 | **$0.00 / month** |
| **`lldap` User Directory** | Rust Lightweight LDAP | GCP Cloud Run / Tiny VM | **~$0.00 - $7.00 / month** |
| **Cloud DNS** | GCP Cloud DNS Managed Zones | GCP Native API | **~$0.45 / month** |
| **TOTAL ESTIMATED COST** | | | **~$0.45 - $7.45 / month** |

> [!IMPORTANT]
> **Never host transient research compute inside `ait-brainlab-mgmt`**. Heavy GPU training workloads and student grant credits must always run in separate **`brainlab-res-*`** workload projects (see [`infra/cloud/`](../infra/cloud/)).
