# AIT Brainlab Base (`brainlab-base`) — AI Assistant Guidelines

## 📌 Repository Overview
This repository serves as the central knowledge base (Obsidian markdown vault), infrastructure runbook, lab service configuration directory, and hardware/asset catalog for **AIT Brainlab** (Asian Institute of Technology).

---

## 🏗 System Architecture & Key Domains

### 1. Core Management Plane (`mgmt/`) — `ait-brainlab-mgmt`
- **Purpose**: Permanent, decoupled, low-cost ($0.45-$7.45/mo) management control plane.
- **Unified Control Plane VM**: Co-hosts **LLDAP** (Identity/POSIX) and **Self-Hosted NetBird** (VPN Control Plane & Signal) on a single lightweight VM (< 400 MB RAM total) with automated Traefik Let's Encrypt SSL. Permanently eliminates device limits.
- **Core Services**:
  - **Cloud DNS**: Authoritative DNS zones for `brain.cs.ait.ac.th` and `dpi.ait.ac.th` (protected with `prevent_destroy = true`).
  - **Identity & Directory (`lldap`)**: POSIX UID/GID mapping for TrueNAS NFS permissions and Linux SSSD.
  - **NetBird Mesh VPN**: Zero-trust WireGuard mesh with Google OAuth2 SSO.
- **Root Governance**: Owned by `brainlab@ait.asia`, `st121413@ait.asia`, and `akraradets@gmail.com`.
- **Implementation Tracker**: Master task checklist (Phases 1–6) in [`mgmt/checklist.md`](mgmt/checklist.md).
- **Invariant**: **Never** provision heavy GPU compute or transient research workloads inside `ait-brainlab-mgmt`.

### 2. Identity & Access Governance (`mgmt/services/identity/`)
- **AuthN (Google OAuth2)**: Handles 100% of identity verification, passwords, and 2FA. Supports `@ait.asia`, `@ait.ac.th`, and approved alumni `@gmail.com`. Graduation/deactivation by AIT automatically revokes access.
- **AuthZ (LLDAP Passwordless Directory)**: LLDAP acts strictly as an authorization and POSIX mapping directory (mapping email $\rightarrow$ UID/GID/home path). LLDAP stores **NO user passwords** for web services.
- **2-Tier Zero-Compute Gatekeeping**: Unprovisioned users fail at the LLDAP lookup stage (< 2ms) without spawning Docker containers or consuming GPU/RAM.
- **Multi-Email Binding**: A single POSIX user record (`username`, numeric `UID`, `GID`, home path `/mnt/HDD/home/<username>/work`) can bind multiple authorized emails (e.g. `stXXXXXX@ait.asia` + `user@gmail.com`) for seamless alumni/graduate continuation without data copying or `chown`.
- **Zero Internal TLS Overhead**: All internal LDAP communication across TrueNAS, Linux SSSD, and Ubuntu Desktops runs through the NetBird WireGuard encrypted mesh tunnel (`ldap://` on port `:3890` with `ldap_id_use_start_tls = false`). No self-signed certificates or Python `ldap3` package hacks.

### 3. Infrastructure Admin Domain (`infra/`)
- **On-Premise Servers (`infra/onprem/`)**: Ubuntu 22.04 LTS servers (`la.cs.ait.ac.th`, `tokyo.cs.ait.ac.th`, `cairo`).
- **NVIDIA CUDA & Runtime**: NVIDIA driver management and Container Toolkit (`runtime: nvidia`).
- **TrueNAS Storage**: Central NFS home directory storage mounted at `/mnt/HDD/home`.
- **Institutional Proxy**: CSIM forward proxy required for outbound traffic (`http://192.41.170.23:3128`).
- **Research Cloud Workloads (`infra/cloud/`)**: Spot GPU templates, GCS buckets, and research grants ($5k Faculty / $1k PhD).
- **Network & VPN (`infra/network/`)**: NetBird mesh VPN, CSIM proxy routing, and DNS topology.

### 4. Service Admin Domain (`services/`)
- **JupyterHub (`services/jupyterhub/`)**: Multi-user hub using `DockerSpawner` mapping user UIDs/GIDs and allocating GPUs with environments (`default`, `nlp`, `cv`).
- **Identity & Access (`services/identity/`)**: `lldap` user directory, Google OAuth2 SSO, and Linux SSSD client configurations.
- **MLflow Platform (`services/mlflow/`)**: Experiment tracking server on `tokyo.cs.ait.ac.th:5000` with TrueNAS artifact storage.
- **Web APIs & Gateway (`services/api/`)**: Traefik reverse proxy and deployed FastAPI / AI demonstration applications.

### 5. Operational Runbooks (`docs/`)
- **Onboarding (`docs/onboarding.md`)**: New member onboarding SOP.
- **Offboarding (`docs/offboarding.md`)**: Data preservation and account archiving SOP.
- **Troubleshooting (`docs/troubleshooting.md`)**: Diagnostic guides for GPU, NFS, proxy, and container issues.
- **Roles Matrix (`docs/roles_and_responsibilities.md`)**: Division of tasks between Infrastructure Admin and Service Admin.

---

## 📁 Repository Directory Structure

```
brainlab-base/
├── README.md                      # Central knowledge base landing page
├── AGENTS.md                      # AI Assistant context and rules (this file)
├── GEMINI.md                      # Link to AGENTS.md
│
├── mgmt/                          # 🛡️ Core Management Plane (ait-brainlab-mgmt)
│   ├── README.md                  # Control plane architecture & governance
│   ├── checklist.md               # Master migration & implementation checklist
│   ├── migration_plan.md          # Zero-downtime on-prem to cloud migration SOP
│   ├── terraform/                 # Dedicated Terraform IaC for Cloud DNS & IAM
│   └── services/                  # Core services (dns, identity/lldap, vpn/netbird)
│
├── infra/                         # 🛠️ Infrastructure Admin Domain
│   ├── onprem/                    # Physical nodes, OS install, GPU, TrueNAS NFS
│   ├── cloud/                     # Research workload templates (Spot GPUs, GCS, credits)
│   └── network/                   # Network routing, CSIM proxy, DNS topology
│
├── services/                      # 🚀 Service Admin Domain
│   ├── jupyterhub/                # Spawner config, Dockerfiles (default, nlp, cv)
│   ├── identity/                  # SSO, Google OAuth, SSSD templates
│   ├── mlflow/                    # MLflow experiment tracking server setup
│   └── api/                       # Traefik reverse proxy & deployed apps
│
├── docs/                          # 📋 Operational SOPs & Handover Runbooks
│   ├── onboarding.md              # Member onboarding checklist
│   ├── offboarding.md             # Account archiving SOP
│   ├── troubleshooting.md         # Incident troubleshooting guide
│   └── roles_and_responsibilities.md # Infra Admin vs Service Admin matrix
│
├── archive/                       # 📦 Archived legacy assets (old api, dockerfiles, images)
└── .obsidian/                     # Obsidian vault settings & plugins
```

---

## 🔒 Security & Safe Operating Protocols
1. **No Hardcoded Secrets**: Never commit plain-text passwords, LDAP administrative bind passwords, SSL private keys (`/etc/letsencrypt/live/`), or `JUPYTERHUB_CRYPT_KEY` values to version control.
2. **Terraform Safety**: Always apply `lifecycle { prevent_destroy = true }` on Cloud DNS zones and GCP Secret Manager keys.
3. **Stateless Control Plane**: The Management VM is 100% disposable ("Cattle, not Pets"). Permanent user research data lives strictly on TrueNAS NFS (`/mnt/HDD/home`).
4. **Human vs Server NetBird Access**: Human researchers authenticate via Google OIDC without setup keys. Headless physical servers and cloud GPU VMs use Secret Manager enrollment keys.
5. **NetBird Data Plane**: NetBird transfers (e.g. large 1TB datasets) are direct peer-to-peer (P2P) and must not be proxied through cloud relays.

---

## 📝 Code & Documentation Standards
- **File Naming**: Use `snake_case.md` for all documentation and configuration templates.
- **Markdown Notes**: Format all documentation in clean, Obsidian-compatible GitHub Flavored Markdown (supporting wikilinks `[[page]]` and standard markdown links).
- **Preserve Existing Configurations**: Maintain comments and docstrings in existing configurations.
