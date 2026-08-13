# GCP Architecture & Infrastructure Documentation: AIT Brainlab

Welcome to the **AIT Brainlab** Google Cloud Platform (GCP) documentation hub. This directory contains the architectural landscape, governance principles, infrastructure management details, funding guides, and implementation tracking lists for our cloud environment.

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

## 3. Documentation Index & Guides

Detailed documentation is organized into dedicated topic files:

1. [**`ait_brainlab-mgmt` Infrastructure & Implementation Checklist**](ait_brainlab_mgmt.md)
   - Deep dive into the **Multi-Account Architecture** supporting `@ait.asia` & `@gmail.com` members for **~$0.45 - $7.45/month**.
   - Contains the **Project Access List**, **Master Task Tracking Checklist (Phases 1–6)**, NetBird Managed Cloud setup ($0.00/mo), Google OIDC authentication ($0.00/mo), `lldap` directory mapping for Linux SSSD and NAS (`cairo:/mnt/HDD/home`), and GCP Cloud DNS.

2. [**How to Get Free Google Cloud Research Credits & TPUs**](research_credits_guide.md)
   - Guide for researchers, PhD students ($1,000/yr), and Faculty ($5,000/yr) on applying for direct Google Cloud Research Grants.
   - Free TPU access via the **TPU Research Cloud (TRC)** program.
   - Step-by-step application walkthrough and GCP Pricing Calculator requirements.

---

## 4. `ait-brainlab-mgmt` Authorized Access List

The `ait-brainlab-mgmt` GCP project is currently accessible and owned by **3 authorized accounts**:

| Authorized Account Email | Role / Scope | Purpose & Description |
| :--- | :--- | :--- |
| **`brainlab@ait.asia`** | Institutional Owner (`roles/owner`) | Primary non-expiring shared team account for lab management. |
| **`st121413@ait.asia`** | Lead Admin (`roles/owner`) | Akraradet Sinsamersuk's university account for daily administration. |
| **`akraradets@gmail.com`** | Billing Owner (`roles/owner` / `Billing Admin`) | Akraradet Sinsamersuk's personal billing owner identity. |
