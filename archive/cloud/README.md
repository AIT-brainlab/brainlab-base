# GCP Architecture & Infrastructure Documentation: AIT Brainlab

Welcome to the **AIT Brainlab** Google Cloud Platform (GCP) and cloud migration hub. This directory contains the architectural landscape, governance principles, Infrastructure as Code (Terraform), service blueprints, migration runbooks, funding guides, and automation scripts for our hybrid cloud environment.

---

## 1. Domain & Organization Landscape

AIT Brainlab operates across multiple university domains and academic entities, supporting members with **`@ait.asia`** and **`@gmail.com`** accounts:

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                DOMAIN LANDSCAPE                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
                                         │
        ┌────────────────────────────────┼────────────────────────────────┐
        ▼                                ▼                                ▼
┌────────────────────────┐      ┌────────────────────────┐      ┌────────────────────────┐
│  Central University    │      │    AIT Brainlab        │      │    DPI Center          │
│      `ait.asia`        │      │  `brain.cs.ait.ac.th`  │      │    `dpi.ait.ac.th`     │
├────────────────────────┤      ├────────────────────────┤      ├────────────────────────┤
│ - Student emails       │      │ - Research Lab Identity│      │ - Institutional Partner│
│ - (`st121413@ait.asia`)│      │ - `brainlab@ait.asia`  │      │ - `dpi-ops@ait.asia`   │
└────────────────────────┘      └────────────────────────┘      └────────────────────────┘
```

### Identity & Governance Matrix

| Entity | Domain / Account | Role in GCP | Governance Rationale |
| :--- | :--- | :--- | :--- |
| **AIT Central** | `ait.asia` (`st121413@ait.asia`) | Student & Individual User Accounts | **Temporary**: Student accounts expire upon graduation. Must *never* own root infrastructure long-term. |
| **AIT Brainlab** | `brain.cs.ait.ac.th` (`brainlab@ait.asia`) | Institutional Shared Management Group | **Permanent**: Core research lab entity. Holds `roles/owner` across lab projects for non-expiring control. |
| **DPI Center** | `dpi.ait.ac.th` (`dpi-ops@ait.asia`) | Partner Center & Namespace Owner | **Institutional**: Managed domain namespace for public center services. |

---

## 2. Decoupled Architecture Model

To guarantee 100% uptime for core DNS and identity services, infrastructure is split into two decoupled planes:

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                          DECOUPLED BILLING & GOVERNANCE MODEL                          │
└────────────────────────────────────────────────────────────────────────────────────────┘
                                           │
         ┌─────────────────────────────────┴─────────────────────────────────┐
         ▼                                                                   ▼
┌──────────────────────────────────────────────┐           ┌──────────────────────────────────────────────┐
│  CORE MANAGEMENT PLANE: `ait-brainlab-mgmt`  │           │  RESEARCH WORKLOAD PLANE: `brainlab-res-*`   │
├──────────────────────────────────────────────┤           ├──────────────────────────────────────────────┤
│ - Billing: Personal / Lab Managed (Permanent)│           │ - Billing: Research Credits / Grant Funds    │
│ - Monthly Cost: ~$0.45 - $7.45/month         │           │ - Workloads: Vertex AI, GPUs, BigQuery, GCS  │
│ - Supports: `@ait.asia` & `@gmail.com` users │           │ - Safeguards: Pub/Sub Auto-Shutdown at 100% │
│ - NetBird Cloud (Free) + Google OIDC (Free)  │           │ - Lifecycle: Created/Archived per grant cycle│
│ - Cloud DNS: `brain.cs.ait.ac.th` & `dpi...` │           └──────────────────────────────────────────────┘
│ - Owners: `brainlab@ait.asia` & Akraradet    │
└──────────────────────────────────────────────┘
```

---

## 3. Directory Layout & Hub Index

```
cloud/
├── README.md                      # GCP Architecture & Hub documentation (this file)
├── docs/                          # Architectural documentation & migration plans
│   ├── ait_brainlab_mgmt.md       # Management plane architecture & task checklist (Phases 1-6)
│   ├── migration_plan.md          # Step-by-step zero-downtime on-prem to cloud migration plan
│   └── research_credits_guide.md  # Guide to obtaining free Google Cloud & TPU research credits
│
├── terraform/                     # Infrastructure as Code (IaC)
│   ├── mgmt/                      # ait-brainlab-mgmt: Cloud DNS, IAM, and project baseline
│   └── workloads/                 # brainlab-res-*: GPU Spot VMs, GCS buckets, budget safeguards
│
├── services/                      # Service configurations for cloud identity & auth
│   ├── lldap/                     # Rust-based lightweight LDAP for Linux SSSD & NAS UIDs
│   ├── netbird/                   # NetBird zero-trust WireGuard mesh VPN setup
│   └── oauth/                     # Google OIDC JupyterHub and web authentication config
│
└── scripts/                       # Migration and operational automation scripts
    ├── export_onprem_ldap.sh      # Export posix accounts from on-prem OpenLDAP
    ├── verify_dns.sh              # Validate Cloud DNS propagation and NS delegation
    └── sssd.conf.template         # Standardized SSSD configuration for Linux nodes & NAS (cairo)
```

---

## 4. Documentation Index & Detailed Guides

1. [**`ait_brainlab_mgmt` Infrastructure & Master Checklist**](docs/ait_brainlab_mgmt.md)
   - Multi-Account Architecture supporting `@ait.asia` & `@gmail.com` members for **~$0.45 - $7.45/month**.
   - Contains the **Project Access List**, **Master Task Tracking Checklist (Phases 1–6)**, NetBird Cloud setup, and Google OIDC.

2. [**On-Premise to GCP Migration Plan**](docs/migration_plan.md)
   - Step-by-step zero-downtime migration guide for transitioning local **NetBird**, **DNS**, and **LDAP** services to GCP & Cloud Services.

3. [**How to Get Free Google Cloud Research Credits & TPUs**](docs/research_credits_guide.md)
   - Guide for researchers ($1,000/yr PhD, $5,000/yr Faculty) on applying for direct Google Cloud Research Grants and free TPUs via the **TPU Research Cloud (TRC)**.

---

## 5. Authorized Access & Root Governance

The `ait-brainlab-mgmt` GCP project is owned and managed by **3 authorized accounts**:

| Authorized Account Email | Role / Scope | Purpose & Description |
| :--- | :--- | :--- |
| **`brainlab@ait.asia`** | Institutional Owner (`roles/owner`) | Primary non-expiring shared team account for lab management. |
| **`st121413@ait.asia`** | Lead Admin (`roles/owner`) | Akraradet Sinsamersuk's university account for daily administration. |
| **`akraradets@gmail.com`** | Billing Owner (`roles/owner` / `Billing Admin`) | Akraradet Sinsamersuk's personal billing owner identity. |
