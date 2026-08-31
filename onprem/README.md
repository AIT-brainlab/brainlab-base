# 🏢 AIT Brainlab On-Premise Infrastructure (`onprem/`)

## 📌 Domain Scope & Architecture Boundaries

This directory manages **100% of On-Premise Physical Infrastructure** located at the AIT Brainlab physical office (CSIM / Room 212).

Unlike the cloud management plane (`mgmt/`), which operates as a stateless GCP control plane (`ait-brainlab-mgmt`), the `onprem/` domain manages local hypervisors, compute nodes (`la`), SAN/NAS storage (`cairo` TrueNAS SCALE), network topology (CSIM LAN `192.41.170.0/24`), and local container/VM workloads.

---

## 🏗 Sub-Directory Architecture

```text
onprem/
├── README.md                  # Central On-Premise Infrastructure landing page
└── terraform/                 # On-Premise Terraform IaC
    └── proxmox/               # Proxmox VE Hypervisor IaC (bpg/proxmox provider)
        ├── README.md          # API Token & Cloud-Init Template Setup SOP
        ├── providers.tf       # bpg/proxmox provider configuration
        ├── main.tf            # Application VM resource definition
        ├── variables.tf       # Configurable VM compute, disk & network variables
        ├── outputs.tf         # VM status, IP, and hardware outputs
        └── cloud-init.yaml.tftpl # Cloud-Init bootstrap template (Docker + NetBird)
```

---

## 🔑 Key Differences: Cloud (`mgmt/`) vs. On-Premise (`onprem/`)

| Metric | Cloud Control Plane (`mgmt/`) | On-Premise Infrastructure (`onprem/`) |
| :--- | :--- | :--- |
| **Location** | GCP `asia-southeast1` (`ait-brainlab-mgmt`) | AIT CSIM Office (`192.41.170.0/24`) |
| **Cost Boundary** | Permanent stateless VM ($0.45-$7.45/mo) | Physical Hardware (Zero cloud compute billing) |
| **Storage Backend** | GCP Cloud Storage (`ait-brainlab-mgmt-tfstate`) | TrueNAS SCALE ZFS Pools (`/mnt/pool-1`) |
| **IaC Provider** | `hashicorp/google` | `bpg/proxmox` |
| **Primary Goal** | Identity, DNS, NetBird Mesh VPN Signal | Heavy GPU compute, multi-tenant app hosting, local printing |
