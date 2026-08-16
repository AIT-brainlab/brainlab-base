# Sequence 2: Cloud DNS Infrastructure (`mgmt/terraform/dns`)

## 📌 Overview & Purpose
This is **Sequence 2 of 3** in the management plane infrastructure.

This module provisions and manages the authoritative Google Cloud DNS zones for:
1. **AIT Brainlab**: `brain.cs.ait.ac.th` (including 14 live service A records for JupyterHub, NetBird, MLflow, OpenWebUI, etc.)
2. **DPI Center**: `dpi.ait.ac.th` (including MX, TXT/SPF, and AWS sandbox delegation)

The state is permanently synchronized in Google Cloud Storage (`gs://ait-brainlab-mgmt-tfstate/dns/default.tfstate`).

---

## 🛡️ Accidental Destruction Safeguard
Both managed zones have `lifecycle { prevent_destroy = true }`. Terraform will **never** delete these zones, protecting you from losing your assigned Google Name Servers.

---

## 🚀 Standard Day-to-Day Workflow (Code-First)

For all normal operations, **never use import scripts**. You simply manage all DNS records through code:

### 1. Initialize (First Time on Any Laptop)
```bash
cd mgmt/terraform/dns
cp terraform.tfvars.example terraform.tfvars
terraform init
```
*(Terraform connects to `gs://ait-brainlab-mgmt-tfstate` and pulls the latest cloud state automatically).*

---

### 2. Adding or Modifying a DNS Record

#### To Add a New Service A Record:
1. Open [`brainlab.tf`](brainlab.tf) and add your new subdomain to `brainlab_records`:
   ```hcl
   locals {
     brainlab_records = {
       "my_new_service" = { name = "newservice.brain.cs.ait.ac.th.", ip = "192.41.170.85", ttl = 300 }
       # ... existing records
     }
   }
   ```
2. Run `terraform plan` and `terraform apply`.  
   *(Terraform provisions the DNS record in 2 seconds and updates the GCS state).*

#### To Remove a DNS Record:
1. Open [`brainlab.tf`](brainlab.tf) and delete the line from `brainlab_records`.
2. Run `terraform plan` and `terraform apply`.

---

## 🔍 Automated Delegation Health Check (Task 2.4)

To automatically test whether delegation is active from the university root registrar (`cs.ait.ac.th` and `ait.ac.th`) to Google Cloud DNS:

```bash
bash check_delegation.sh
```

**Output on Success**:
```
✅ PASS: brain.cs.ait.ac.th is successfully delegated to Google Cloud DNS!
✅ PASS: jupyterhub.brain.cs.ait.ac.th resolves to 192.41.170.39
✅ PASS: dpi.ait.ac.th is successfully delegated to Google Cloud DNS!
🎉 ALL DELEGATIONS ARE ACTIVE & HEALTHY!
```

---

## 🆘 Day-0 Migration & Disaster Recovery (When to Use `import_live_records.sh`)

> [!NOTE]
> **`import_live_records.sh` is ONLY for Day-0 initial setup or emergency disaster recovery.**  
> During normal operations, Terraform reads and writes state directly from the GCS bucket (`gs://ait-brainlab-mgmt-tfstate/dns`).

If your GCS state file is ever accidentally corrupted/wiped, or if someone created records manually in the GCP Web Console and you need to resync:

```bash
# 1. Run the automated live records importer
bash import_live_records.sh

# 2. Verify alignment with zero drift
terraform plan
```

---

## ➡️ Next Step
Once Cloud DNS is deployed, proceed to **Sequence 3: Secret Manager**:
👉 [**Continue to `mgmt/terraform/secrets/README.md`**](../secrets/README.md)
