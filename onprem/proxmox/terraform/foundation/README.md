# 🛡️ Proxmox Host Foundation IaC (`onprem/terraform/foundation/`)

## 📌 Domain Scope & Architecture

This Terraform IaC module manages **Day-0 Proxmox Host Governance and SSO Identity Integration** directly on the AIT Brainlab on-premise hypervisor (`192.41.170.19`).

Just like `mgmt/terraform/foundation/` manages GCP project prerequisites, `onprem/terraform/foundation/` manages host-level configurations (Google OIDC Authentication Realm, SysAdmin Administrator ACL permissions, and host realm policies).

Remote Terraform state is persisted centrally in GCS:
- **Bucket**: `ait-brainlab-mgmt-tfstate`
- **Prefix**: `onprem/foundation`

---

## 🏗 Directory Layout

```text
onprem/terraform/foundation/
├── README.md                   # Operator SOP & Architecture Guide (this file)
├── providers.tf                # bpg/proxmox provider & GCS state backend
├── main.tf                     # Google OIDC Realm & SysAdmin ACL resources
├── variables.tf                # Proxmox endpoint, API tokens, OIDC parameters
├── outputs.tf                  # Realm name & SysAdmin mapping outputs
├── secrets.auto.tfvars         # Git-ignored API token configuration
└── secrets.auto.tfvars.example # Template reference
```

---

## 🚀 Execution Guide

```bash
cd onprem/terraform/foundation/

# Initialize GCS backend & provider
terraform init

# Plan host governance resources
terraform plan

# Apply host foundation settings
terraform apply
```
