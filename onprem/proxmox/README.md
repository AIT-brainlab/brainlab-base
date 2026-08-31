# 🖥️ Proxmox VE Hypervisor Host `pve1` (`onprem/proxmox/`)

> **Primary On-Premise Hypervisor**: Serves as the central physical virtualization node at the AIT Brainlab office (`192.41.170.19`), co-hosting production project containers, SDN virtual networks, research staging environments, and multi-tenant Application VMs.

---

## 📌 Hardware & Storage Infrastructure Baseline

| Component | Discovered Live Value | Description / Assignment |
| :--- | :--- | :--- |
| **Node Hostname** | **`pve1`** *(Alias: `proxmox`)* | FQDN: `pve1.brain.cs.ait.ac.th` |
| **Management IP** | **`192.41.170.19/24`** | Connected via physical management port `enp1s0f0` (Gateway: `192.41.170.23`) |
| **CPU Capacity** | **128 vCPUs** | Multi-socket high-performance compute host |
| **Memory Capacity** | **134.8 GB RAM** | High-density memory pool (~4.8 GB host usage) |
| **Primary Datastore (`WDBlue`)** | **2.0 TB Total (~1.36 TB Free)** | Type: `lvm`. Primary storage pool for VM root disks (`images, rootdir`) |
| **Secondary Datastore (`local-lvm`)** | **374.5 GB Total (~290.4 GB Free)** | Type: `lvmthin`. Secondary thin-provisioned storage pool |
| **Template Storage (`local`)** | **100.8 GB Total (~54.7 GB Free)** | Type: `dir`. Stores ISOs, Cloud-Init user-data snippets, and container templates (`iso, vztmpl, backup`) |

---

## 🌐 SDN Virtual Networks (VNets) & Bridges

| VNet / Bridge Name | Zone Type | IPAM / DHCP Engine | Subnet / Purpose |
| :--- | :---: | :---: | :--- |
| **`vmbr1`** | Physical Bridge | Manual / CSIM | Frontend Physical 10G High-Speed LAN (`enp2s0`) |
| **`internet`** | SDN `simple` | **`dnsmasq`** | Proxmox SDN NAT VNet with automated DHCP (`10.10.20.0/24`) |

---

## 🖥️ Master Virtual Machine Inventory & Network Map

| VM ID | Hostname / Purpose | vCPUs | RAM | Disk Size | Primary Network & MAC Address | Status | Notes / Assignment |
| :---: | :--- | :---: | :---: | :---: | :--- | :---: | :--- |
| **`100`** | **`proxy`** | 4 | 8 GB | 50 GB | `net0`: `vmbr1` (`192.41.170.39/24`) | 🟢 **Live** | On-Premise 10G Edge Proxy VM (Traefik SSL/HTTP Edge Proxy) |
| **`101`** | **`ml`** | 4 | 16 GB | 60 GB | `net0`: `vmbr1` (`192.41.170.105/24`) | 🟢 **Live** | MLflow experiment tracking server (`ml.brain.cs.ait.ac.th`) |
| **`106`** | `aitgpt-dev` | 32 | 32 GB | 450 GB | `net0`: `vmbr1` (`192.41.170.17/24`) | Stopped | Large Model development VM |
| **`119`** | **`dlms-server`** | 16 | 32 GB | 200 GB | `net0`: **`internet`** (SDN VNet / `10.10.250.1` / `100.74.18.96`) | 🟢 **Live** | Dedicated DLMS Server (AI Vision & RTSP Ingest `192.168.1.2:554`) |
| **`120`** | **`brainlab-services`** | 4 | 8 GB | 60 GB | `net0`: **`internet`** (SDN VNet / `100.74.10.218`) | 🟢 **Live** | General Lab Administrative Services (Web Printing Portal `print.brain.cs.ait.ac.th`) |
| **`900`** | `VM 900` | 8 | 64 GB | - | `net0`: `vmbr1` (`BC:24:11:2F:39:CC`) | Stopped | Base VM template |

---

## 🏗 Proxmox IaC Architecture (Mirroring GCP `mgmt/`)

Proxmox infrastructure follows a **Decoupled 2-Layer Terraform Architecture** stored in GCS remote state (`gs://ait-brainlab-mgmt-tfstate`):

```text
onprem/proxmox/
├── README.md                           # Master Host & VM Inventory Guide (this file)
│
└── terraform/
    ├── foundation/                     # 🛡️ Layer 1: Proxmox Host Governance
    │   ├── main.tf                     # Host DNS (brain.cs.ait.ac.th), Timezone (Asia/Bangkok), & SysAdmin ACLs
    │   ├── providers.tf                # bpg/proxmox provider & GCS state (prefix: onprem/proxmox/foundation)
    │   ├── variables.tf                # Node name (proxmox/pve1), endpoint, credentials
    │   └── secrets.auto.tfvars         # Git-ignored API token configuration
    │
    └── vms/                            # 🚀 Layer 2: Virtual Machine Provisioner
        ├── main.tf                     # Application VM 119 (32 vCPUs, 64GB RAM, 150GB disk on WDBlue)
        ├── providers.tf                # bpg/proxmox provider & GCS state (prefix: onprem/proxmox/vms)
        ├── variables.tf                # VM hardware, network, and cloud-init parameters
        ├── cloud-init.yaml.tftpl       # Automated Docker Engine + NetBird WireGuard mesh enrollment
        └── secrets.auto.tfvars         # Git-ignored API token & NetBird setup key
```

---

## 🚀 Operator SOP

### 1. Host Foundation Execution (`foundation/`)
```bash
cd onprem/proxmox/terraform/foundation/
terraform init -reconfigure
terraform plan
terraform apply
```

### 2. VM Provisioning Execution (`vms/`)
```bash
cd onprem/proxmox/terraform/vms/
terraform init -reconfigure
terraform plan
terraform apply
```
