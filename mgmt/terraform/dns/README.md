# Sequence 2: Cloud DNS Infrastructure (`mgmt/terraform/dns`)

## 📌 Overview & Purpose
This is **Sequence 2 of 3** in the management plane infrastructure.

This module provisions and manages the authoritative Google Cloud DNS zones for:
1. **AIT Brainlab**: `brain.cs.ait.ac.th` (including 14 live A records for JupyterHub, NetBird, MLflow, OpenWebUI, etc.)
2. **DPI Center**: `dpi.ait.ac.th` (including MX, TXT/SPF, and AWS sandbox delegation)

---

## 🛡️ Accidental Destruction Safeguard
Both managed zones have `lifecycle { prevent_destroy = true }`. Terraform will **never** delete these zones, protecting you from losing your assigned Google Name Servers.

---

## 🚀 Step-by-Step Execution Tutorial

### Step 1: Initialize Configuration & Download Plugins
```bash
cd mgmt/terraform/dns
cp terraform.tfvars.example terraform.tfvars
terraform init
```

---

### Step 2: Adopt Live GCP Zones & Records (Import)
If your zones (`ait-brainlab` and `dpi-center`) and DNS records already exist in the GCP Console, run the automated import script:

```bash
bash import_live_records.sh
```

**What the script does**:
* Adopts the `ait-brainlab` and `dpi-center` managed zones into Terraform state.
* Adopts all 14 live A records (`jupyterhub`, `netbird`, `mlflow`, etc.).
* Adopts all MX, TXT, and NS records for DPI.

---

### Step 3: Dry-Run Plan
```bash
terraform plan
```
**What to verify in the plan**:
* Confirms **`0 to destroy`**.
* Shows all live records synchronized and managed by code.

---

### Step 4: Apply & Deploy
```bash
terraform apply
```

---

### Step 5: Verify & Capture Delegation Name Servers
Print the 4 Google Name Servers assigned to your zones:
```bash
terraform output brainlab_name_servers
terraform output dpi_name_servers
```

**Next Action**: Submit these 4 Name Servers to the parent registrar (`cs.ait.ac.th`) to complete university delegation!

---

## ➡️ Next Step
Once Cloud DNS is active, proceed to **Sequence 3: Secret Manager**:
👉 [**Continue to `mgmt/terraform/secrets/README.md`**](../secrets/README.md)
