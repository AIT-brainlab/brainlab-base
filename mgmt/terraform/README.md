# Terraform Infrastructure as Code: `ait-brainlab-mgmt` (`mgmt/terraform`)

This Terraform module automates the provisioning of the **Core Management Plane** on Google Cloud Platform for **AIT Brainlab**.

---

## 🏗️ Resources Provisioned

1. **GCP APIs**: Enables `dns`, `run`, `compute`, `iam`, `secretmanager`, `monitoring`, and `billingbudgets`.
2. **Authoritative Cloud DNS Zones**:
   - `brain.cs.ait.ac.th` (with baseline A records for `hub` and `tokyo`).
   - `dpi.ait.ac.th` (Partner center zone).
3. **IAM Governance**: Grants `roles/owner` to `brainlab@ait.asia`, `st121413@ait.asia`, and `akraradets@gmail.com`.
4. **Automation Service Account**: `brainlab-mgmt-automation@ait-brainlab-mgmt.iam.gserviceaccount.com` (DNS Admin).
5. **Secret Manager**: Securely stores random generated `lldap-jwt-secret` and `lldap-admin-password`.
6. **Monitoring Channels**: Alert channels sending budget threshold notifications to `brainlab@ait.asia` and `akraradets@gmail.com`.

---

## 🚀 Step-by-Step Deployment Runbook

### Step 1: Authenticate with Google Cloud
Ensure you are authenticated using your admin account (`akraradets@gmail.com` or `st121413@ait.asia`):

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project ait-brainlab-mgmt
```

---

### Step 2: Configure Terraform Variables
```bash
cd mgmt/terraform
cp terraform.tfvars.example terraform.tfvars
```
*(Review and edit `terraform.tfvars` if your server IP addresses have changed).*

---

### Step 3: Initialize & Plan
```bash
terraform init
terraform plan
```

---

### Step 4: Apply & Deploy
```bash
terraform apply
```
Type `yes` to confirm.

---

### Step 5: Post-Deployment NS Delegation
Once `terraform apply` finishes, it outputs the 4 authoritative name servers for each zone:
```bash
terraform output brainlab_zone_name_servers
```
Copy these 4 NS records and submit them to the parent domain registrar (`cs.ait.ac.th`) to complete delegation!
