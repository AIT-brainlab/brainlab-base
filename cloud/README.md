# GCP Architecture & Infrastructure Documentation: AIT Brainlab

---

## 1. Organization & Project Situation

AIT Brainlab operates across multiple university domains, centers, and academic identities. Understanding this structure is essential for proper GCP cloud governance and preventing resource lockouts.

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

### 1.1 Identity & Governance Matrix

| Entity | Domain / Account | Role in GCP | Lifespan & Governance Rationale |
| :--- | :--- | :--- | :--- |
| **AIT Central** | `ait.asia` (`st121413@ait.asia`) | Student & Individual User Accounts | **Temporary**: Student accounts expire upon graduation. Must *never* own root infrastructure or billing long-term. |
| **AIT Brainlab** | `brain.cs.ait.ac.th` (`brainlab@ait.asia`) | Institutional Shared Management Group | **Permanent**: Core research lab entity. Holds `roles/owner` across all lab projects to ensure continuity. |
| **DPI Center** | `dpi.ait.ac.th` (`dpi-ops@ait.asia`) | Partner Center & Namespace Owner | **Institutional**: Managed domain namespace for public center services. |

---

## 2. Core Control Plane: `ait-brainlab-mgmt`

The `ait-brainlab-mgmt` (or `brainlab-mgmt`) project serves as the core management backbone ("control plane") for AIT Brainlab. 

### 2.1 Core Responsibilities
- **Public & Private Cloud DNS**: Authoritative DNS resolution for `brain.cs.ait.ac.th` and `dpi.ait.ac.th`.
- **Identity Management & SSO**: Authentik (Docker container) providing OIDC for web apps and LDAP Outpost (`:389`) for local lab compute nodes & NAS home directories (`cairo:/mnt/HDD/home`).
- **Zero-Trust Network Access (ZTNA)**: NetBird Control Server managing WireGuard mesh VPN connecting GCP resources to local hardware.
- **Reverse Proxy & TLS**: Traefik / Caddy providing automated Let's Encrypt TLS certificates.

### 2.2 System Architecture Diagram

```
                       [ Internet / Remote Users ]
                                    │
                                    ▼
                     ┌─────────────────────────────┐
                     │    Delegated Parent DNS     │
                     │       `cs.ait.ac.th`        │
                     └──────────────┬──────────────┘
                                    │ NS Records
                                    ▼
 ┌───────────────────────────────────────────────────────────────────────┐
 │ GCP PROJECT: `ait-brainlab-mgmt`                                      │
 │                                                                       │
 │   ┌───────────────────────────────────────────────────────────────┐   │
 │   │ Cloud DNS Managed Zones (`brain.cs.ait.ac.th` & `dpi.ait.ac.th`)│   │
 │   └──────────────────────────────┬────────────────────────────────┘   │
 │                                  │                                    │
 │                                  ▼                                    │
 │   ┌───────────────────────────────────────────────────────────────┐   │
 │   │ Compute Engine VM (`brainlab-core-vm` | `e2-medium`)          │   │
 │   │ Static External IPv4: <RESERVED_STATIC_IP>                    │   │
 │   │                                                               │   │
 │   │  ┌─────────────────────────────────────────────────────────┐  │   │
 │   │  │ Reverse Proxy (Caddy / Traefik)                         │  │   │
 │   │  │  - Automatic TLS Certificates (Let's Encrypt)           │  │   │
 │   │  └──────────────┬───────────────────────────┬──────────────┘  │   │
 │   │                 │                           │                 │   │
 │   │  ┌──────────────▼──────────┐     ┌──────────▼──────────────┐  │   │
 │   │  │ Authentik (SSO / IdP)   │     │ NetBird Control Server  │  │   │
 │   │  │  - OIDC / Web Auth      │     │  - WireGuard Mesh ZTNA  │  │   │
 │   │  │  - LDAP Outpost (:389)  │     │  - Signal / Management  │  │   │
 │   │  └─────────────────────────┘     └─────────────────────────┘  │   │
 │   └──────────────────────────────┬────────────────────────────────┘   │
 └──────────────────────────────────┼────────────────────────────────────┘
                                    │
            ┌───────────────────────┴───────────────────────┐
            │ NetBird Overlay Mesh Network                  │
            ▼                                               ▼
┌─────────────────────────┐                     ┌─────────────────────────┐
│ Local On-Prem Compute   │                     │ Local On-Prem NAS       │
│ - SSSD -> Authentik LDAP│                     │ - Shares `/home` (NFS)  │
│ - Joined to NetBird     │                     │ - Joins Authentik LDAP  │
└─────────────────────────┘                     └─────────────────────────┘
```

### 2.3 Billing & Funding Model for `ait-brainlab-mgmt`
- **Billing Owner**: Personally / Lab-managed by Akraradet Sinsamersuk & `brainlab@ait.asia`.
- **Monthly Cost**: Negligible (~$0.50 - $2.00/month for Cloud DNS and minimal control plane traffic).
- **Strategic Rationale**: Institutional centers or research grants come and go, but AIT Brainlab is permanent. Funding `ait-brainlab-mgmt` independently guarantees that Cloud DNS for `brain.cs.ait.ac.th` and `dpi.ait.ac.th` **never experiences downtime** due to credit expirations or grant transitions.

### 2.4 Ownership & Access Control
| Role | Identity / Email | Scope & Permissions |
| :--- | :--- | :--- |
| **Institutional Owner** | `brainlab@ait.asia` | `roles/owner` (Non-expiring shared team account) |
| **Lead Admin & Billing Owner** | Akraradet Sinsamersuk (`089-122-2061`) | `roles/owner`, `roles/billing.admin` |
| **Co-Infrastructure Lead** | Phue Pwint Thwe (`062-638-0858`) | `roles/owner`, `roles/dns.admin` |

---

## 3. Decoupled Research Workloads & Credit Funding

Research workloads are decoupled from the core management plane to isolate spending and prevent research credit depletion from affecting core DNS/SSO.

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
│ - Monthly Cost: ~$0.50 - $5.00/month         │           │ - Workloads: Vertex AI, GPUs, BigQuery, GCS  │
│ - Cloud DNS: `brain.cs.ait.ac.th` & `dpi...` │           │ - Safeguards: Pub/Sub Auto-Shutdown at 100% │
│ - Core SSO: Authentik LDAP (`:389`)          │           │ - Lifecycle: Created/Archived per grant cycle│
│ - ZTNA Mesh: NetBird Control Server          │           └──────────────────────────────────────────────┘
│ - Owners: `brainlab@ait.asia` & Akraradet    │
└──────────────────────────────────────────────┘
```

### 3.1 Transitioning from Expired Free Trial to Research Credits
If your GCP credits screen currently shows **"Free Trial (Expired)"**, follow this procedure:

1. **Upgrade Billing Account**: Go to `GCP Console > Billing > Billing Account Overview` and click **Upgrade** to convert to a Standard Billing Account.
2. **Redeem Research Credits**: Redeem your Google Cloud Research Credit code under `Billing > Credits`.
3. **Assign to Research Projects**: Link research projects (`brainlab-res-ai`, `brainlab-res-data`) to the Credit Billing Account.
4. **Enable Cost Safeguards**: Set budget threshold alerts (50%, 80%, 90%, 100%) and enable Pub/Sub VM auto-shutdown so out-of-pocket charges never occur on research workloads.

---

## 4. User Access Management & Student Lifecycle

1. **Scoped Student Permissions**: External researchers and students (`@ait.asia`) are granted project-specific IAM roles (e.g., `roles/vertexai.user`, `roles/compute.instanceAdmin.v1`) on research projects (`brainlab-res-*`).
2. **Offboarding Policy**: When a student completes their thesis or graduates, revoking their IAM role from the research project takes 1 click, leaving all lab DNS, core infrastructure, and project data intact.
3. **Resource Optimization**:
   - **Spot / Preemptible VMs**: Used by default for ML training jobs (60-90% cost savings).
   - **Vertex AI Workbench**: Auto-shutdown enabled after 30 minutes of inactivity.
   - **GCS Storage Lifecycle**: Raw datasets transition from `Standard` $\rightarrow$ `Nearline` (>30d) $\rightarrow$ `Coldline`/`Archive` (>90d).
