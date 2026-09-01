# 🖥️ Proxmox VE Hypervisor Architecture & Governance (`docs/infra/onprem/proxmox_setup.md`)

> **Central On-Premise Hypervisor**: Serves as the physical virtualization host at the AIT Brainlab office (`192.41.170.19`), co-hosting multi-tenant project containers (Remote Web Print, DLMS project backends, RTSP camera ingests, and research staging VMs).

---

## 📌 Hardware & Storage Infrastructure Baseline

| Component | Discovered Live Value | Description / Assignment |
| :--- | :--- | :--- |
| **Node Name** | **`proxmox`** | Physical Proxmox VE hypervisor host |
| **Management IP** | **`192.41.170.19/24`** | Connected via physical management port `enp1s0f0` (Gateway: `192.41.170.23`) |
| **Total CPU Capacity** | **128 vCPUs** | Multi-socket high-performance compute host |
| **Total Memory Capacity** | **134.8 GB RAM** | High-density memory pool |
| **Primary Datastore (`WDBlue`)** | **2.0 TB Total (~1.0 TB Free)** | Type: `lvm`. Primary storage pool for VM root disks (`images, rootdir`) |
| **Secondary Datastore (`local-lvm`)** | **374.5 GB Total (~268.6 GB Free)** | Type: `lvmthin`. Secondary thin-provisioned storage pool |
| **Template Storage (`local`)** | **100.8 GB Total (~54.7 GB Free)** | Type: `dir`. Stores ISOs, Cloud-Init user-data snippets, and container templates (`iso, vztmpl, backup`) |

---

## 🌐 Network Interface & Topology

```mermaid
flowchart TD
    subgraph PhysicalInterfaces ["🔌 Physical Network Ports"]
        P1["enp1s0f0 (Management: 192.41.170.19/24)"]
        P2["enp2s0 (Frontend 10G CSIM LAN Interface)"]
    end

    subgraph ProxmoxBridges ["🌉 Proxmox VE Network Bridges & SDN"]
        VMBR1["vmbr1: Physical Bridge (10G CSIM LAN)<br/>• Directly attached to enp2s0"]
        SDN_INT["internet: SDN NAT VNet (10.10.20.0/24 / 10.10.250.0/16)<br/>• Outbound NAT to Management Port<br/>• Automated DHCP Engine (dnsmasq)"]
    end

    subgraph TenantVMs ["🖥️ Tenant Virtual Machines"]
        ProxyVM["brainlab-proxy (VM ID 100)<br/>• net0: vmbr1 (192.41.170.39)<br/>• net1: internet SDN (10.10.250.x)<br/>• Edge Traefik + SSL Offloading"]
        DLMSVM["dlms-server (VM ID 119)<br/>• net0: internet SDN (10.10.250.1)<br/>• NetBird: 100.74.18.96<br/>• Project-Level Traefik (Port 80)"]
        ServicesVM["brainlab-services (VM ID 120)<br/>• net0: internet SDN (10.10.250.2)<br/>• NetBird: 100.74.10.218<br/>• Web Print & Lab Services"]
    end

    P2 --> VMBR1
    P1 --> SDN_INT
    VMBR1 --> ProxyVM
    SDN_INT --> ProxyVM
    SDN_INT --> DLMSVM
    SDN_INT --> ServicesVM
    ProxyVM -.->|"Reverse Proxy :80"| DLMSVM
    ProxyVM -.->|"Reverse Proxy :80"| ServicesVM
```

---

## 🏗 Proxmox IaC Architecture (Mirroring GCP `mgmt/`)

Just like the Cloud Management Plane (`mgmt/`), On-Premise Proxmox infrastructure follows a **Decoupled 2-Layer Terraform Architecture**:

```text
onprem/proxmox/
├── README.md                           # Master Host & VM Inventory Guide
│
└── terraform/
    ├── foundation/                     # 🛡️ Layer 1: Host Foundation & Governance
    │   ├── main.tf                     # Host DNS (brain.cs.ait.ac.th), Timezone, & SysAdmin ACLs
    │   ├── network_sdn.tf              # Proxmox SDN Zone & VNet 'internet' (dnsmasq)
    │   ├── variables.tf                # Node name, endpoint, credentials
    │   └── secrets.auto.tfvars         # Git-ignored API token configuration
    │
    └── vms/                            # 🚀 Layer 2: Virtual Machines Provisioner
        ├── main.tf                     # VMs (VM 100 proxy, VM 119 dlms-server, VM 120 services)
        ├── routes.tf                   # Declarative Traefik dynamic routes generator (routes.yaml)
        ├── variables.tf                # Hardware specs, proxy_routes map, and cloud-init parameters
        ├── outputs.tf                  # VM IDs, IPs, and configured routes
        └── cloud-init.yaml.tftpl       # Automated Docker Engine + Traefik file provider + NetBird
```

---

## 🔐 Google OIDC Single Sign-On (SSO) Governance

Human SysAdmins authenticate to the Proxmox Web GUI (`https://192.41.170.19:8006`) using Google OpenID Connect:

### 1. GCP OAuth Console Configuration
- **Authorized Origins**: `https://192.41.170.19:8006`
- **Authorized Redirect URIs**: `https://192.41.170.19:8006/oauth2/callback`

### 2. Proxmox OIDC Realm Creation CLI
```bash
# Add Google OIDC Realm
pveum realm add google --type openid \
  --issuer-url https://accounts.google.com \
  --client-id "<CLIENT_ID>.apps.googleusercontent.com" \
  --client-key "<CLIENT_SECRET>" \
  --username-claim email \
  --autocreate 1 \
  --default 0 \
  --comment "Google OAuth2 SSO"

# Assign SysAdmin Administrator Permissions
pveum acl modify / --user "akraradet@ait.asia@google" --role Administrator
```

---

## 🚀 Provisioning Workflow

### 1. Terraform Plan & Apply
```bash
cd onprem/terraform/proxmox/

# Verify plan against live host
terraform plan

# Apply VM creation
terraform apply
```

### 2. Automated Bootstrap Execution
Upon boot, Cloud-Init automatically:
1. Installs `docker.io`, `docker-compose-v2`, `curl`, `jq`, and `netbird`.
2. Sets timezone to `Asia/Bangkok`.
3. Auto-enrolls the VM into the NetBird WireGuard overlay mesh under setup key `dlms-server-enrollment` with groups `prj-dlms-servers` and `brainlab-cluster`.

---

## 🔮 Strategic Long-Term AI Platform Roadmap (Standalone Proxmox Hosts + K3s VM Cluster)

```mermaid
flowchart TD
    subgraph ProxmoxHosts ["🖥️ Standalone Proxmox VE Hypervisors"]
        Node1["pve1.brain.cs.ait.ac.th (192.41.170.19)<br/>• Independent Standalone Hypervisor Host<br/>• Application VMs (Web Print, DLMS) on vmbr0 NAT"]
        Node2["pve2.brain.cs.ait.ac.th (192.41.170.85)<br/>• Independent Standalone GPU Hypervisor Host<br/>• Dual RTX A6000 GPUs via PCIe Passthrough (vfio-pci)"]
    end

    subgraph K3sVMCluster ["☸️ Unified K3s Kubernetes Cluster (VM Layer)"]
        VM1["VM 119 on pve1 (brainlab-app-vm)"]
        VM2["VM 200 on pve2 (la-gpu-vm)"]
        
        GPUOp["✂️ NVIDIA GPU Operator & MPS Time-Slicing<br/>• 2x RTX A6000s (96GB VRAM) sliced into 12-24 Virtual Slots"]
        Z2JH["⚡ Zero-to-JupyterHub (KubeSpawner)<br/>• Interactive JupyterLab & VS Code in Browser<br/>• Auto-spawns pods with GPU slot allocations"]
        MLflow["📊 MLflow Server (ml.brain.cs.ait.ac.th)<br/>• Experiment tracking & model registry"]
        Optuna["🎯 Optuna HPO<br/>• Automated hyperparameter tuning inside Python notebooks"]
    end

    Node1 -.-> VM1
    Node2 -.->|"PCIe GPU Passthrough"| VM2
    VM1 <--> K3sVMCluster
    VM2 <--> K3sVMCluster
    Z2JH --> GPUOp
    Z2JH <--> MLflow
    Z2JH <--> Optuna
```

### Migration Phases:
1. **Phase 1 (Current Baseline)**: Stand up Proxmox host governance and Application VM 119 (`brainlab-app-vm`) on standalone `pve1` (`192.41.170.19`).
2. **Phase 2 (Standalone Proxmox `pve2`)**: Convert physical bare-metal GPU server `la` (`192.41.170.85`) to standalone Proxmox VE (`pve2.brain.cs.ait.ac.th`) and configure PCIe GPU passthrough (`vfio-pci`).
3. **Phase 3 (Multi-Node K3s Cluster at VM Layer)**: Join VMs across `pve1` and `pve2` into a single K3s Kubernetes cluster, enable NVIDIA MPS Time-Slicing (12-24 student slots), and deploy Zero-to-JupyterHub (`KubeSpawner`) with MLflow and Optuna.
