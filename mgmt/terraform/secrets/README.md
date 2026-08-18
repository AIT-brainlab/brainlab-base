# Sequence 3: Secret Manager Infrastructure (`mgmt/terraform/secrets`)

## 📌 Overview & Purpose
This is **Sequence 3 of 6** in the management plane infrastructure.

This module provisions **GCP Secret Manager** and generates cryptographically secure, high-entropy tokens and passwords required to bootstrap **LLDAP** and the Management VM. 

The state is permanently synchronized in Google Cloud Storage (`gs://ait-brainlab-mgmt-tfstate/secrets/default.tfstate`).

---

## 🔐 Seeded Secrets & Purpose

| Secret ID | Generation Method | Purpose | Managed In |
| :--- | :--- | :--- | :---: |
| **`lldap-jwt`** | 32-character random string | Cryptographic signing key for LLDAP user sessions | Sequence 3 (`secrets/`) |
| **`lldap-admin-password`** | 24-character high-entropy password | Initial password for the LLDAP web admin portal | Sequence 3 (`secrets/`) |
| **`netbird-setup-key`** | Generated from NetBird API | Reusable enrollment token for physical servers & GPU VMs | Sequence 6 (`vpn/`) |
| **`netbird-mgmt-token`** | Generated from NetBird API | Personal Access Token (PAT) for Terraform automation | Sequence 4/6 (`vm/`/`vpn/`) |

---

## 🛡️ Accidental Destruction Safeguard
All Secret Manager secrets have `lifecycle { prevent_destroy = true }`. Terraform will **refuse to delete** active keys, protecting your live authentication tokens.

---

## 🚀 Standard Day-to-Day Workflow (Code-First)

For all normal operations, you manage secrets declaratively through code:

### 1. Initialize (First Time on Any Laptop)
```bash
cd mgmt/terraform/secrets
cp terraform.tfvars.example terraform.tfvars
terraform init
```
*(Terraform connects to `gs://ait-brainlab-mgmt-tfstate` and pulls the latest cloud state automatically).*

---

### 2. Adding a New Secret via Code

#### To Add a New Secret:
1. Open [`main.tf`](main.tf) and declare the new secret resource:
   ```hcl
   resource "google_secret_manager_secret" "my_new_secret" {
     secret_id = "my-service-api-key"
     replication { auto {} }
     lifecycle { prevent_destroy = true }
   }

   resource "google_secret_manager_secret_version" "my_new_secret_version" {
     secret      = google_secret_manager_secret.my_new_secret.id
     secret_data = "MY_INITIAL_SECRET_VALUE"
   }
   ```
2. Run `terraform plan` and `terraform apply`.  
   *(Terraform provisions the secret in 2 seconds and updates the GCS state).*

---

## 🔍 Automated Secrets Health Check (Task 3.2 — Zero Leakage)

To verify that all required secrets exist in GCP Secret Manager **without exposing or printing their values** to your terminal screen:

```bash
bash check_secrets.sh
```

**Output on Success**:
```
==> Checking secret 'lldap-jwt'... ✅ PASS (Active Version: 1, State: ENABLED)
==> Checking secret 'lldap-admin-password'... ✅ PASS (Active Version: 1, State: ENABLED)
==> Checking secret 'netbird-setup-key'... ✅ PASS (Active Version: 1, State: ENABLED)
🎉 ALL REQUIRED SECRETS EXIST & ARE SECURELY STORED!
```

---

## 💻 How to Fetch Secret Payloads from Terminal (When Needed)

If an administrator explicitly needs to view a secret payload:

```bash
# 1. Fetch LLDAP Admin Initial Password
gcloud secrets versions access latest --secret="lldap-admin-password" --project="ait-brainlab-mgmt"

# 2. Fetch LLDAP JWT Secret Key
gcloud secrets versions access latest --secret="lldap-jwt" --project="ait-brainlab-mgmt"

# Note: 'netbird-setup-key' is generated and managed atomically in Sequence 6 (vpn/)
```

---

## 🆘 Day-0 Migration & Disaster Recovery (When to Use `import`)

> [!NOTE]
> **Import commands are ONLY for Day-0 initial setup or emergency disaster recovery.**  
> During normal operations, Terraform reads and writes state directly from the GCS bucket (`gs://ait-brainlab-mgmt-tfstate/secrets`).

If your GCS state file is ever accidentally corrupted/wiped and you need to adopt existing secrets back into Terraform:

```bash
PROJECT_ID="ait-brainlab-mgmt"

terraform import google_secret_manager_secret.jwt_secret "projects/$PROJECT_ID/secrets/lldap-jwt"
terraform import google_secret_manager_secret.admin_password "projects/$PROJECT_ID/secrets/lldap-admin-password"

terraform plan
```

---

## ➡️ Next Step: Sequence 4 (Management VM Engine)
All 3 foundational Terraform infrastructure sequences are complete! You are now ready to proceed to **Sequence 4: Launching the Management VM Engine** (Traefik + LLDAP + NetBird):
👉 [**Continue to `mgmt/terraform/vm/README.md`**](../vm/README.md)
