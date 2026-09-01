# 🖥️ Proxmox VE Application VM Provisioner (`onprem/proxmox/terraform/vms/`)

## 📌 Architecture & Overview

This Terraform IaC module manages on-premise virtual machines and dynamic edge ingress on the AIT Brainlab Proxmox VE hypervisor (`192.41.170.19`).

It provisions a decoupled **Two-Tier Ingress & Application VM Stack** using the `bpg/proxmox` provider, with persistent remote state stored in Google Cloud Storage (`gs://ait-brainlab-mgmt-tfstate/onprem/proxmox/vms`).

---

## 🏗️ Directory Layout (1-File-Per-VM Architecture)

```text
onprem/proxmox/terraform/vms/
├── README.md              # Documentation & Runbook (this file)
├── providers.tf           # bpg/proxmox provider & GCS backend config
├── main.tf                # Read-only Proxmox data sources
├── vm-proxy.tf            # 🌐 VM 100: brainlab-proxy (10G Public Ingress)
├── vm-services.tf         # 🖨️ VM 120: brainlab-services (Web Print & Lab Administration)
├── vm-dlms.tf             # 🚀 VM 119: dlms-server (Dedicated AI Vision / DLMS Platform)
├── routes.tf              # ⚡ Traefik GitOps dynamic route sync (0.5s hot-reload)
├── variables.tf           # Sizing, static IPs, and proxy_routes declarative map
├── outputs.tf             # Endpoint URLs and service summaries
└── cloud-init.yaml.tftpl  # Base Day 0 Cloud-Init template (Docker + NetBird)
```

---

## 🌐 Live VM & Network Inventory

| VM ID | Hostname | Config File | Network Interfaces | Role / Capabilities |
| :--- | :--- | :--- | :--- | :--- |
| **100** | `brainlab-proxy` | [`vm-proxy.tf`](file:///Users/akraradets/Projects/AIT-brainlab/brainlab-base/onprem/proxmox/terraform/vms/vm-proxy.tf) | `net0`: `192.41.170.39/24` (vmbr1)<br>`net1`: `10.10.250.100/16` (SDN) | Traefik v3 Edge Proxy (Port 443 SSL, Rate Limiting, 25MB Body Cap) |
| **119** | `dlms-server` | [`vm-dlms.tf`](file:///Users/akraradets/Projects/AIT-brainlab/brainlab-base/onprem/proxmox/terraform/vms/vm-dlms.tf) | `net0`: `10.10.250.119/16` (SDN) | Dedicated DLMS Research Platform (16 vCPUs / 32GB RAM) |
| **120** | `brainlab-services` | [`vm-services.tf`](file:///Users/akraradets/Projects/AIT-brainlab/brainlab-base/onprem/proxmox/terraform/vms/vm-services.tf) | `net0`: `10.10.250.120/16` (SDN) | Web Print Portal (`services/printing`) & Shared Lab Tools |

---

## ⚡ Dynamic Ingress GitOps (0s Downtime Route Management)

To add, edit, or remove a public service route:
1. Declare the domain and target in `proxy_routes` inside [`variables.tf`](file:///Users/akraradets/Projects/AIT-brainlab/brainlab-base/onprem/proxmox/terraform/vms/variables.tf):
   ```hcl
   proxy_routes = {
     my_service = {
       domain     = "my-service.brain.cs.ait.ac.th"
       target_url = "http://10.10.250.120:80"
       aliases    = []
     }
   }
   ```
2. Run `terraform apply`.
3. `terraform_data.sync_traefik_routes` pushes the updated `routes.yaml` directly to `brainlab-proxy` over NetBird MagicDNS in **0.5 seconds**.
4. Traefik automatically hot-reloads the new route with **0 VM destruction and 0 container restarts**.

---

## 🚀 Execution & Deployment Runbook

### Step 1: Initialize & Plan
```bash
cd onprem/proxmox/terraform/vms/

# Initialize GCS backend and provider
terraform init

# Validate execution plan
terraform plan
```

### Step 2: Apply
```bash
terraform apply
```

