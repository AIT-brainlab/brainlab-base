# Documentation & Admin Runbooks (`docs/`)

Welcome to the central documentation, operational runbooks, and handover guides for **AIT Brainlab**.

---

## 📚 Runbooks & Documentation Index

### 1. 🛠️ Infrastructure & Physical Runbooks (`docs/infra/`)
| Guide | Purpose | Target Hosts |
| :--- | :--- | :--- |
| [**On-Premise Server SOPs**](infra/onprem/README.md) | Ubuntu 22.04, NVIDIA CUDA, TrueNAS NFS/iSCSI, SSSD, and Docker | `la`, `cairo`, `tokyo` |
| [**Network & Mesh VPN**](infra/network/README.md) | NetBird mesh routing, CSIM Squid proxy, and DNS topology | Physical & cloud nodes |
| [**Research Cloud Workloads**](infra/cloud/README.md) | Spot GPU templates, GCS buckets, and research grants ($5k/$1k) | Google Cloud |

---

### 2. 📋 Operational SOPs & Governance (`docs/`)
| Runbook | Purpose | Target Audience |
| :--- | :--- | :--- |
| [**User Onboarding**](onboarding.md) | Step-by-step procedure for creating accounts, NetBird VPN access, and NAS directories | Service & Infra Admins |
| [**Member Offboarding**](offboarding.md) | Archiving user datasets, deactivating accounts, and reclaiming resources | Service Admin |
| [**SysAdmin Troubleshooting**](troubleshooting.md) | Diagnostic and resolution steps for CUDA, NFS, Proxy, and Jupyter issues | All Admins |
| [**Roles & Handover**](roles_and_responsibilities.md) | Division of operational responsibilities between Infra and Service Admins | Future Maintainers |
| [**Hybrid Cloud Architecture**](hybrid_cloud_storage.md) | Storage decoupling, K8s CSI abstraction, and unified POSIX identity across clusters | Infra & Cloud Admins |
