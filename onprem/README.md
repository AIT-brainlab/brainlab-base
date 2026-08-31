# 🏢 AIT Brainlab On-Premise Infrastructure (`onprem/`)

## 📌 Architecture Vision & Host Separation

This directory manages **100% of On-Premise Physical Hardware** located at the AIT Brainlab office (CSIM LAN `192.41.170.0/24`).

To maintain clean separation between physical host targets and cloud infrastructure (`mgmt/`), the `onprem/` domain is partitioned by **Host Architecture**:

```text
onprem/
├── README.md                           # Master On-Premise Architecture Guide (this file)
│
├── proxmox/                            # 🖥️ Physical Proxmox VE Hypervisor Host (192.41.170.19)
│   ├── README.md                       # Proxmox architecture & hardware inventory
│   │
│   ├── terraform/                      # Proxmox IaC (bpg/proxmox provider)
│   │   ├── foundation/                 # 🛡️ Layer 1: Host Foundation (DNS, Timezone, Storage, NAT, IAM)
│   │   └── vms/                        # 🚀 Layer 2: VM Provisioner (App VM 119, DLMS VMs, Project VMs)
│   │
│   └── ansible/                        # Day-1 Host Provisioning & Maintenance Playbooks
│
└── la/                                 # ⚡ Bare-Metal GPU Server la.cs.ait.ac.th (192.41.170.85)
    ├── README.md                       # Dual RTX A6000 GPU setup, JupyterHub, TrueNAS NFS mounts
    ├── terraform/                      # Bare-Metal OS/hardware state management (if applicable)
    └── ansible/                        # CUDA drivers, SSSD POSIX integration, Docker runtime
```

---

## 🔑 Proxmox VE IaC Lifecycle & GCS Remote State

Proxmox VE infrastructure uses a **Decoupled 2-Layer Model** mirroring GCP:

1. **Host Foundation (`onprem/proxmox/terraform/foundation/`)**:
   - **Scope**: Manages host search domains (`brain.cs.ait.ac.th`), host timezone (`Asia/Bangkok`), Google OIDC SSO realm, and SysAdmin administrator ACL permissions (`Administrator`).
   - **GCS Remote State**: `gs://ait-brainlab-mgmt-tfstate` with prefix `onprem/proxmox/foundation`.

2. **VM Provisioner (`onprem/proxmox/terraform/vms/`)**:
   - **Scope**: Provisions virtual machines (`brainlab-app-vm`, ID 119) attached to **NAT Bridge `vmbr0`** (`10.10.20.0/24`) on storage datastore `WDBlue`.
   - **Bootstrap**: Uploads Cloud-Init user-data snippets (`local`) for automated Docker Engine + NetBird WireGuard mesh enrollment.
   - **GCS Remote State**: `gs://ait-brainlab-mgmt-tfstate` with prefix `onprem/proxmox/vms`.
