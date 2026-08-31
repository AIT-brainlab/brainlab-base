# 🖥️ Proxmox VE Application VM Provisioner (`onprem/terraform/proxmox/`)

## 📌 Architecture & Overview

This Terraform IaC module provisions local multi-tenant virtual machines (such as the shared Application VM for **Remote Web Print** and **DLMS Project workloads**) directly on the AIT Brainlab on-premise Proxmox VE hypervisor (`192.41.170.19`).

It leverages the modern `bpg/proxmox` provider to automate VM creation, Cloud-Init user-data snippet upload, static IP binding on CSIM LAN (`vmbr0`), and automated NetBird VPN enrollment on first boot.

---

## 🏗 Directory Layout

```text
onprem/terraform/proxmox/
├── README.md              # Operator SOP & Prerequisite Guide (this file)
├── providers.tf       # Provider configuration (bpg/proxmox ~> 0.60.0)
├── main.tf            # Proxmox VM & Cloud-Init snippet resources
├── variables.tf       # VM sizing, networking, and token variables
├── outputs.tf         # VM ID, IP address, and MAC address outputs
└── cloud-init.yaml.tftpl # Cloud-Init template (Docker + NetBird Mesh setup)
```

---

## 🔑 One-Time Prerequisites on Proxmox VE Host (`192.41.170.19`)

### 1. Create API Token for Terraform Automation
Run on the Proxmox host shell (`ssh root@192.41.170.19`):

```bash
# 1. Create automation user in pve realm
pveum user add terraform-prov@pve --comment "Terraform Automation Service Account"

# 2. Assign Administrator role on root pool
pveum acl modify / --user terraform-prov@pve --role Administrator

# 3. Generate API Token
pveum user token add terraform-prov@pve tf-token --privsep 0
```

> **Note**: Save the returned Token ID (`terraform-prov@pve!tf-token`) and Secret Key safely into GCP Secret Manager or export them as environment variables.

---

### 2. Download Ubuntu 24.04 LTS Cloud Image to Proxmox Storage
Run on the Proxmox host shell:

```bash
cd /var/lib/vz/template/iso/
wget https://cloud-images.ubuntu.com/minimal/releases/noble/release/ubuntu-24.04-minimal-cloudimg-amd64.img
```

---

## 🚀 Execution Guide

### Step 1: Export Authentication Variables
```bash
export TF_VAR_proxmox_api_token="terraform-prov@pve!tf-token=YOUR_API_TOKEN_UUID"
export TF_VAR_netbird_setup_key="YOUR_EPHEMERAL_NETBIRD_SETUP_KEY"
```

### Step 2: Initialize & Apply Terraform
```bash
cd onprem/terraform/proxmox/

# Initialize provider & backend
terraform init

# Validate configuration
terraform plan

# Apply & provision VM
terraform apply
```

---

## 📋 Verification Baseline
After `terraform apply` completes:
1. Proxmox VE Web GUI (`https://192.41.170.19:8006`) displays VM ID `119` (`brainlab-app-vm`) running on `pve`.
2. The VM boots up, applies cloud-init user-data, installs Docker Engine, and enrolls into NetBird mesh under Setup Key `dlms-server-enrollment`.
3. Verify reachability over WireGuard mesh: `ping 100.103.x.x` or direct CSIM IP `ping 192.41.170.19`.
