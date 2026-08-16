# Sequence 3: Secret Manager Infrastructure (`mgmt/terraform/secrets`)

## 📌 Overview & Purpose
This is **Sequence 3 of 3** in the management plane infrastructure.

This module provisions **GCP Secret Manager** and generates cryptographically secure, high-entropy tokens and passwords required by **LLDAP** and **NetBird**.

---

## 🔐 Secrets Provisioned & Managed

| Secret ID | Generation Method | Purpose |
| :--- | :--- | :--- |
| **`lldap-jwt-secret`** | 32-character random string | Cryptographic signing key for LLDAP user sessions |
| **`lldap-admin-password`** | 24-character high-entropy password | Initial password for the LLDAP web admin portal |
| **`netbird-onprem-setup-key`** | Secure placeholder / setup key | Reusable enrollment token for physical servers & GPU VMs |

---

## 🛡️ Accidental Destruction Safeguard
All Secret Manager secrets have `lifecycle { prevent_destroy = true }`. Terraform will **refuse to delete** active keys, protecting your live authentication tokens.

---

## 🚀 Step-by-Step Execution Tutorial

### Step 1: Initialize Configuration & Download Plugins
```bash
cd mgmt/terraform/secrets
cp terraform.tfvars.example terraform.tfvars
terraform init
```

---

### Step 2: Dry-Run Plan
```bash
terraform plan
```
**What to verify in the plan**:
* Enables `secretmanager.googleapis.com`.
* Creates the 3 secret objects and their initial secret versions.
* Confirms **`0 to destroy`**.

---

### Step 3: Apply & Deploy
```bash
terraform apply
```
Type `yes` when prompted.

---

### Step 4: How to Safely Fetch Secrets from Your Terminal
You can retrieve the generated secrets securely via the `gcloud` CLI:

```bash
# 1. Fetch LLDAP Admin Initial Password
gcloud secrets versions access latest --secret="lldap-admin-password" --project="ait-brainlab-mgmt"

# 2. Fetch LLDAP JWT Secret Key
gcloud secrets versions access latest --secret="lldap-jwt-secret" --project="ait-brainlab-mgmt"

# 3. Fetch NetBird Setup Key
gcloud secrets versions access latest --secret="netbird-onprem-setup-key" --project="ait-brainlab-mgmt"
```

---

## ➡️ Next Step: Control Plane VM Deployment
All 3 Terraform infrastructure sequences are complete! You are now ready to launch the **Unified Management VM** (LLDAP + Self-Hosted NetBird):
👉 [**Continue to `mgmt/services/identity/README.md`**](../../services/identity/README.md)
