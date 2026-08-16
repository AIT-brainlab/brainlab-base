# AIT Brainlab Base (`brainlab-base`) — AI Assistant Guidelines

## 📌 Repository Overview
This repository serves as the central knowledge base (Obsidian markdown vault), infrastructure runbook, lab service configuration directory, and hardware/asset catalog for **AIT Brainlab** (Asian Institute of Technology).

---

## 🏗 System Architecture & Key Services

### 1. Infrastructure Admin Domain (`infra/`)
- **On-Premise Servers (`infra/onprem/`)**: Ubuntu 22.04 LTS servers (`la.cs.ait.ac.th`, `tokyo.cs.ait.ac.th`, `cairo`).
- **NVIDIA CUDA & Runtime**: NVIDIA driver management and Container Toolkit (`runtime: nvidia`).
- **TrueNAS Storage**: Central NFS home directory storage mounted at `/mnt/HDD/home`.
- **Institutional Proxy**: CSIM forward proxy required for outbound traffic (`http://192.41.170.23:3128`).
- **Cloud Infrastructure (`infra/cloud/`)**: GCP Management Plane (`ait-brainlab-mgmt`) and Terraform IaC for Cloud DNS (`brain.cs.ait.ac.th`, `dpi.ait.ac.th`) and research workloads (`brainlab-res-*`).
- **Network & VPN (`infra/network/`)**: NetBird Mesh VPN connecting physical servers, cloud nodes, and remote members.

### 2. Service Admin Domain (`services/`)
- **JupyterHub (`services/jupyterhub/`)**: Multi-user hub using `DockerSpawner` mapping user UIDs/GIDs and allocating GPUs with environments (`default`, `nlp`, `cv`).
- **Identity & Access (`services/identity/`)**: `lldap` user directory, Google OAuth2 SSO, and Linux SSSD client configurations.
- **MLflow Platform (`services/mlflow/`)**: Experiment tracking server on `tokyo.cs.ait.ac.th:5000` with TrueNAS artifact storage.
- **Web APIs & Gateway (`services/api/`)**: Traefik reverse proxy and deployed FastAPI / AI demonstration applications.

### 3. Operational Runbooks (`docs/`)
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
├── docs/                          # Operational SOPs & Handover Runbooks
│   ├── onboarding.md              # Member onboarding checklist
│   ├── offboarding.md             # Account archiving SOP
│   ├── troubleshooting.md         # Incident troubleshooting guide
│   └── roles_and_responsibilities.md # Infra Admin vs Service Admin matrix
│
├── infra/                         # 🛠️ Infrastructure Admin Domain
│   ├── onprem/                    # Physical nodes, OS install, GPU, TrueNAS NFS
│   ├── cloud/                     # GCP Terraform, Cloud DNS, research grants
│   └── network/                   # NetBird VPN, CSIM proxy, DNS topology
│
├── services/                      # 🚀 Service Admin Domain
│   ├── jupyterhub/                # Spawner config, Dockerfiles (default, nlp, cv)
│   ├── identity/                  # lldap, Google OAuth SSO, SSSD templates
│   ├── mlflow/                    # MLflow experiment tracking server setup
│   └── api/                       # Traefik reverse proxy & deployed apps
│
├── examples/                      # Example research notebooks (e.g., MLflow)
└── .obsidian/                     # Obsidian vault settings & plugins
```

---

## 🔒 Security & Safe Operating Protocols
1. **No Hardcoded Secrets**: Never commit plain-text passwords, LDAP administrative bind passwords, SSL private keys (`/etc/letsencrypt/live/`), or `JUPYTERHUB_CRYPT_KEY` values to version control.
2. **Proxy Awareness**: Ensure proxy environment variables (`http_proxy`, `https_proxy`) and apt proxy rules are set for all setup scripts and Dockerfiles.
3. **Storage Mounts**: Persistent user data lives under `/mnt/HDD/home/{username}/work` and `/mnt/HDD/home/{username}/.ssh`.

---

## 📝 Code & Documentation Standards
- **File Naming**: Use `snake_case.md` for all documentation and configuration templates.
- **Markdown Notes**: Format all documentation in clean, Obsidian-compatible GitHub Flavored Markdown (supporting wikilinks `[[page]]` and standard markdown links).
- **Preserve Existing Configurations**: Maintain comments and docstrings in existing configurations.
