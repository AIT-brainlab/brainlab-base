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

1. [**Infrastructure Implementation Plan & Tracking Checklist**](implementation_plan.md)
   - Step-by-step implementation roadmap, task tracking status table (Phases 1–6), weekly schedule, and task owners.

2. [**`ait_brainlab-mgmt` Infrastructure Documentation**](ait_brainlab_mgmt.md)
   - Deep dive into the **Multi-Account Architecture** supporting `@ait.asia` & `@gmail.com` members for **~$0.45 - $7.45/month**.
   - NetBird Managed Cloud setup ($0.00/mo), Google OIDC authentication ($0.00/mo), `lldap` directory mapping for Linux SSSD and NAS (`cairo:/mnt/HDD/home`), and GCP Cloud DNS.

3. [**How to Get Free Google Cloud Research Credits & TPUs**](research_credits_guide.md)
   - Guide for researchers, PhD students ($1,000/yr), and Faculty ($5,000/yr) on applying for direct Google Cloud Research Grants.
   - Free TPU access via the **TPU Research Cloud (TRC)** program.
   - Step-by-step application walkthrough and GCP Pricing Calculator requirements.

---

## 4. Quick Contacts

| Role | Name / Email | Contact |
| :--- | :--- | :--- |
| **Shared Lab Management** | `brainlab@ait.asia` | Core Team Account |
| **Lead Admin & Billing Owner** | Akraradet Sinsamersuk | `089-122-2061` |
| **Co-Infrastructure Lead** | Phue Pwint Thwe | `062-638-0858` |
