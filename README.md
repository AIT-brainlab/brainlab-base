# AIT Brainlab Base (`brainlab-base`)

The central knowledge base, equipment inventory, service documentation, and infrastructure repository for **AIT Brainlab** (Asian Institute of Technology).

---

## 📌 Repository Organization

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                               AIT BRAINLAB ADMINISTRATION                              │
└────────────────────────────────────────────────────────────────────────────────────────┘
                                           │
         ┌─────────────────────────────────┼─────────────────────────────────┐
         ▼                                 ▼                                 ▼
┌─────────────────────────┐       ┌─────────────────────────┐       ┌─────────────────────────┐
│  1. INFRASTRUCTURE      │       │      2. SERVICES        │       │   3. RUNBOOKS & DOCS    │
│  [`infra/`](infra/)     │       │  [`services/`](services/)│       │     [`docs/`](docs/)    │
├─────────────────────────┤       ├─────────────────────────┤       ├─────────────────────────┤
│ • On-Premise Servers    │       │ • JupyterHub Platform   │       │ • Member Onboarding     │
│ • NVIDIA GPU Drivers    │       │ • Identity & Google SSO │       │ • Data Offboarding      │
│ • TrueNAS NFS Storage   │       │ • MLflow Experiment Hub │       │ • SysAdmin Debugging    │
│ • GCP Terraform & DNS   │       │ • Traefik & Web APIs    │       │ • Role Handover Matrix  │
│ • NetBird VPN Mesh      │       │ • Python Environments   │       │                         │
└─────────────────────────┘       └─────────────────────────┘       └─────────────────────────┘
```

---

## 📚 Core Navigation

### 1. 🛠️ [Infrastructure Domain (`infra/`)](infra/README.md)
- [**`infra/onprem/`**](infra/onprem/README.md): Ubuntu 22.04 installation, NVIDIA GPU drivers, TrueNAS NFS mounting (`/mnt/HDD/home`), and Docker engine.
- [**`infra/cloud/`**](infra/cloud/README.md): GCP Management Plane (`ait-brainlab-mgmt`), Terraform IaC for Cloud DNS and Spot GPU research workloads, and research grant guides ($5k Faculty / $1k PhD).
- [**`infra/network/`**](infra/network/README.md): NetBird mesh VPN setup, CSIM proxy configuration (`192.41.170.23:3128`), and DNS topology.

### 2. 🚀 [Services Domain (`services/`)](services/README.md)
- [**`services/jupyterhub/`**](services/jupyterhub/README.md): Multi-user GPU JupyterLab container environment (`nlp`, `cv`, `default` Dockerfiles) and systemd configuration.
- [**`services/identity/`**](services/identity/README.md): Lightweight LDAP (`lldap`) directory, Google OAuth2 Single Sign-On, and Linux SSSD mapping.
- [**`services/mlflow/`**](services/mlflow/README.md): MLflow tracking server setup on `tokyo.cs.ait.ac.th:5000` with TrueNAS artifact storage.
- [**`services/api/`**](services/api/README.md): Traefik edge reverse proxy routing and deployed FastAPI & AI demonstration applications.

### 3. 📋 [Operational Runbooks (`docs/`)](docs/README.md)
- [**User Onboarding**](docs/onboarding.md): Step-by-step SOP for new researchers and students.
- [**Member Offboarding**](docs/offboarding.md): Data archiving and access revocation SOP.
- [**SysAdmin Troubleshooting**](docs/troubleshooting.md): Incident runbook for CUDA, NFS, Proxy, and container failures.
- [**Roles & Handover**](docs/roles_and_responsibilities.md): Matrix of responsibilities for Infrastructure Admins and Service Admins.

---

## 🔒 Security & Safe Operating Protocols
- **No Hardcoded Secrets**: Never commit passwords, private keys, or API tokens to version control.
- **Proxy Aware**: Outbound traffic on CSIM network requires `http://192.41.170.23:3128`.
- **Persistent User Data**: Always stored on TrueNAS at `/mnt/HDD/home/{username}/work`.