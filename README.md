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
         ▼                               ▼                           ▼
┌─────────────────┐             ┌─────────────────┐         ┌─────────────────┐
│  CORE MGMT      │             │    SERVICES     │         │ RUNBOOKS & DOCS │
│ [`mgmt/`](mgmt/)│             │[`services/`](...)│       │ [`docs/`](docs/)│
├─────────────────┤             ├─────────────────┤         ├─────────────────┤
│ • ait-brainlab- │             │ • JupyterHub    │         │ • Infra Runbooks│
│   mgmt ($5/mo)  │             │ • Web Print     │         │ • Onboarding    │
│ • Cloud DNS     │             │ • Dual A6000 GPU│         │ • Offboarding   │
│ • NetBird Mesh  │             │ • DockerSpawner │         │ • Troubleshooting
│ • lldap Directory│            │                 │         │ • Admin Roles   │
└─────────────────┘             └─────────────────┘         └─────────────────┘
```

---

## 📚 Core Navigation

### 1. 🛡️ [Core Management Plane (`mgmt/`)](mgmt/README.md)
The decoupled, permanent control plane running under GCP project **`ait-brainlab-mgmt`** (~$0.45 to $7.45/month):
- [**Master Task Checklist**](mgmt/checklist.md): 8-phase roadmap (Phases 1–6 Verified: Foundation, VM Engine, Identity, NetBird Networks, Cutover).
- [**Identity-as-Code**](mgmt/identity/): Declarative `members.yaml` and GraphQL user synchronizer.
- [**Network-as-Code**](mgmt/vpn/): Declarative NetBird Software-Defined Networks (`network.yaml`).
- [**Modular Terraform IaC**](mgmt/terraform/): Consolidated 2-layer Terraform (`foundation/`, `vm/`).

### 2. 🚀 [Services Domain (`services/`)](services/README.md)
- [**`services/jupyterhub/`**](services/jupyterhub/README.md): Multi-user GPU JupyterLab container environment on `la` (dual RTX A6000, TrueNAS NFS).
- [**`services/printing/`**](services/printing/README.md): Remote Web Print Portal (`docker-cups`) bridging cloud to CSIM printer.

### 3. 📋 [Operational Runbooks & Docs (`docs/`)](docs/README.md)
- [**Infrastructure & Server Runbooks**](docs/infra/onprem/README.md): Ubuntu 22.04, NVIDIA CUDA, TrueNAS NFS/iSCSI, SSSD, and 1-command bootstrap.
- [**Network & Mesh VPN**](docs/infra/network/README.md): NetBird mesh VPN setup, CSIM proxy configuration, and DNS topology.
- [**Research Cloud Workloads**](docs/infra/cloud/README.md): Spot GPU templates, GCS buckets, and research grants ($5k/$1k).
- [**User Onboarding**](docs/onboarding.md): Step-by-step SOP for new researchers and students.
- [**Member Offboarding**](docs/offboarding.md): Data archiving and access revocation SOP.
- [**SysAdmin Troubleshooting**](docs/troubleshooting.md): Incident runbook for CUDA, NFS, Proxy, and container failures.
- [**Roles & Handover**](docs/roles_and_responsibilities.md): Matrix of responsibilities for Infrastructure Admins and Service Admins.

### 4. 📦 [Archived Assets (`archive/`)](archive/README.md)
Historical configurations, legacy Docker images, screenshots, and older notebooks preserved for reference.

---

## 🐍 Python Environment Management (`uv`)

This repository uses [**`uv`**](https://docs.astral.sh/uv/) for blazing-fast, deterministic Python dependency management:

```bash
# 1. Sync virtual environment and install all dependencies
uv sync

# 2. Run Identity GitOps synchronization
uv run mgmt/identity/sync_users.py

# 3. Run NetBird VPN GitOps synchronization
uv run mgmt/vpn/sync_netbird.py

# 4. Run Day 1 Ansible mesh operations playbooks
uv run ansible-playbook -i mgmt/ansible/inventory.ini mgmt/ansible/enroll_netbird.yml
```

---

## 🔒 Security & Safe Operating Protocols
- **No Hardcoded Secrets**: Never commit passwords, private keys, or API tokens to version control.
- **Proxy Aware**: Outbound traffic on CSIM network requires `http://192.41.170.82:3128`.
- **Persistent User Data**: Always stored on TrueNAS at `/mnt/pool-1/home/{username}`.