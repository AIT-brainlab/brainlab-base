# AIT Brainlab Base (`brainlab-base`)

The central knowledge base, equipment inventory, service documentation, and infrastructure repository for **AIT Brainlab** (Asian Institute of Technology).

---

## 📌 Repository Organization

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                       AIT BRAINLAB ARCHITECTURE                                         │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────┘
                                                     │
         ┌───────────────────────────┬───────────────┴───────────────┬───────────────────────────┐
         ▼                           ▼                               ▼                           ▼
┌─────────────────┐         ┌─────────────────┐             ┌─────────────────┐         ┌─────────────────┐
│  CORE MGMT      │         │ INFRASTRUCTURE  │             │    SERVICES     │         │ RUNBOOKS & DOCS │
│ [`mgmt/`](mgmt/)│         │ [`infra/`](infra)│             │[`services/`](...)│       │ [`docs/`](docs/)│
├─────────────────┤         ├─────────────────┤             ├─────────────────┤         ├─────────────────┤
│ • ait-brainlab- │         │ • On-Prem Server│             │ • JupyterHub    │         │ • Onboarding    │
│   mgmt ($5/mo)  │         │ • NVIDIA GPUs   │             │ • MLflow Server │         │ • Offboarding   │
│ • Cloud DNS     │         │ • TrueNAS NFS   │             │ • Traefik Proxy │         │ • Debugging     │
│ • NetBird Mesh  │         │ • Research GPUs │             │ • Web Demo APIs │         │ • Admin Roles   │
│ • lldap Directory│        │ • Proxy Routing │             │ • User Images   │         │                 │
└─────────────────┘         └─────────────────┘             └─────────────────┘         └─────────────────┘
```

---

## 📚 Core Navigation

### 1. 🛡️ [Core Management Plane (`mgmt/`)](mgmt/README.md)
The decoupled, permanent control plane running under GCP project **`ait-brainlab-mgmt`** (~$0.45 to $7.45/month):
- [**Master Task Checklist**](mgmt/checklist.md): 7-phase roadmap (Phases 1–3 Completed: IAM, DNS, Secrets).
- [**Migration Plan**](mgmt/migration_plan.md): Step-by-step zero-downtime transition SOP.
- [**Modular Terraform IaC**](mgmt/terraform/): 6 independent modules (`iam/`, `dns/`, `secrets/`, `vm/`, `identity/`, `vpn/`) backed by GCS remote state (`gs://ait-brainlab-mgmt-tfstate`).

### 2. 🛠️ [Infrastructure Domain (`infra/`)](infra/README.md)
- [**`infra/onprem/`**](infra/onprem/README.md): Ubuntu 22.04 installation, NVIDIA GPU drivers, TrueNAS NFS mounting (`/mnt/HDD/home`), and Docker engine.
- [**`infra/cloud/`**](infra/cloud/README.md): Research compute templates (Spot GPU VMs, GCS buckets) and Google Cloud research credit guides ($5k Faculty / $1k PhD).
- [**`infra/network/`**](infra/network/README.md): NetBird mesh VPN setup, CSIM proxy configuration (`192.41.170.23:3128`), and DNS topology.

### 3. 🚀 [Services Domain (`services/`)](services/README.md)
- [**`services/jupyterhub/`**](services/jupyterhub/README.md): Multi-user GPU JupyterLab container environment (`nlp`, `cv`, `default` Dockerfiles) and systemd configuration.
- [**`services/identity/`**](services/identity/README.md): Lightweight LDAP (`lldap`) directory, Google OAuth2 Single Sign-On, and Linux SSSD mapping.
- [**`services/mlflow/`**](services/mlflow/README.md): MLflow tracking server setup on `tokyo.cs.ait.ac.th:5000` with TrueNAS artifact storage.
- [**`services/api/`**](services/api/README.md): Traefik edge reverse proxy routing and deployed FastAPI & AI demonstration applications.

### 4. 📋 [Operational Runbooks (`docs/`)](docs/README.md)
- [**User Onboarding**](docs/onboarding.md): Step-by-step SOP for new researchers and students.
- [**Member Offboarding**](docs/offboarding.md): Data archiving and access revocation SOP.
- [**SysAdmin Troubleshooting**](docs/troubleshooting.md): Incident runbook for CUDA, NFS, Proxy, and container failures.
- [**Roles & Handover**](docs/roles_and_responsibilities.md): Matrix of responsibilities for Infrastructure Admins and Service Admins.

### 5. 📦 [Archived Assets (`archive/`)](archive/README.md)
Historical configurations, legacy Docker images, screenshots, and older notebooks preserved for reference.

---

## 🔒 Security & Safe Operating Protocols
- **No Hardcoded Secrets**: Never commit passwords, private keys, or API tokens to version control.
- **Proxy Aware**: Outbound traffic on CSIM network requires `http://192.41.170.23:3128`.
- **Persistent User Data**: Always stored on TrueNAS at `/mnt/HDD/home/{username}/work`.