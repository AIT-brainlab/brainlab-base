# Sequence 1: IAM Governance & Root Owners (`mgmt/terraform/iam`)

## 📌 Overview & Purpose
This is **Sequence 1 of 3** in the management plane infrastructure. 

This module enforces the multi-account ownership policy for **`ait-brainlab-mgmt`** and manages the Terraform automation service account. The state is permanently synchronized in Google Cloud Storage (`gs://ait-brainlab-mgmt-tfstate/iam/default.tfstate`).

---

## 👥 Seeded Identities & Roles

| Principal / Account | Role | Purpose |
| :--- | :--- | :--- |
| `user:brainlab@ait.asia` | `roles/owner` | Permanent institutional lab account |
| `user:st121413@ait.asia` | `roles/owner` | Lead System Administrator |
| `user:akraradets@gmail.com` | `roles/owner` | Permanent personal billing admin |
| `serviceAccount:brainlab-mgmt-terraform@...` | `roles/dns.admin` | Dedicated service account used by Terraform & CI/CD |

---

## 🚀 Standard Day-to-Day Workflow (Code-First)

For all normal operations, **never use import scripts**. You simply manage everything through code:

### 1. Initialize (First Time on Any Laptop)
```bash
cd mgmt/terraform/iam
cp terraform.tfvars.example terraform.tfvars
terraform init
```
*(Terraform connects to `gs://ait-brainlab-mgmt-tfstate` and pulls the latest cloud state automatically).*

---

### 2. Adding or Removing Project Admins

#### To Add a New Admin:
1. Open [`main.tf`](main.tf) and add their email to `authorized_owners`:
   ```hcl
   locals {
     authorized_owners = [
       "user:brainlab@ait.asia",
       "user:st121413@ait.asia",
       "user:akraradets@gmail.com",
       "user:new_admin@ait.asia",  # 👈 Added new admin
     ]
   }
   ```
2. Run `terraform plan` and `terraform apply`.  
   *(Terraform grants `roles/owner` in 3 seconds and updates the GCS state).*

#### To Remove an Admin:
1. Open [`main.tf`](main.tf) and delete their email line.
2. Run `terraform plan` and `terraform apply`.

---

## 🆘 Day-0 Migration & Disaster Recovery (When to Use `import`)

> [!NOTE]
> **Import commands are ONLY for Day-0 initial setup or emergency disaster recovery.**  
> During normal operations, Terraform reads state directly from the GCS bucket.

If someone accidentally makes changes manually in the GCP Web Console, or if state needs to be resynced from scratch:

```bash
# Fetch and import live project owners into state
PROJECT_ID="ait-brainlab-mgmt"

OWNERS=$(gcloud projects get-iam-policy "$PROJECT_ID" \
  --flatten="bindings[].members" \
  --format="value(bindings.members)" \
  --filter="bindings.role:roles/owner")

for MEMBER in $OWNERS; do
  terraform import "google_project_iam_member.owners[\"$MEMBER\"]" "$PROJECT_ID roles/owner $MEMBER" || true
done

terraform plan
```

---

## ➡️ Next Step
Once IAM governance is deployed, proceed to **Sequence 2: Cloud DNS**:
👉 [**Continue to `mgmt/terraform/dns/README.md`**](../dns/README.md)
