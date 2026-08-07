# GCP

| Level          | Component                         | University Analogy        | What it manages                                            |
| -------------- | --------------------------------- | ------------------------- | ---------------------------------------------------------- |
| Identity Level | Google Workspace / Cloud Identity | Student/Faculty Registry  | Users (user@dpi.ait.ac.th), passwords, groups, and email.  |
| Root Level     | GCP Organization                  | The University Campus     | The master container owned by your domain (dpi.ait.ac.th). |
| Grouping Level | Folders (Optional)                | Departments / Labs        | Logical groups (e.g., Research Projects, Production Apps). |
| Unit Level     | Projects (Mandatory)              | Individual Lab Rooms      | APIs, permissions, quotas, and billing links.              |
| Base Level     | Resources                         | Equipment inside the room | VMs, Cloud Storage buckets, Databases, GPUs.               |

# Infrastructure Documentation: `ait-brainlab-mgmt`  
## 1. Executive Summary & Purpose  
The ait-brainlab-mgmt Google Cloud project serves as the core management backbone ("control plane") for the AIT Brainlab organization (50 users). It hosts critical identity management, zero-trust network access (ZTNA), private/public DNS resolution, and core platform administrative services.  
To ensure high availability and blast-radius isolation, general compute workloads and experimental applications are isolated in a separate project (`ait-brainlab-compute`).  

## 2. High-Level System Architecture

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
 │   │ Cloud DNS Managed Public Zone (`brain.cs.ait.ac.th`)          │   │
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