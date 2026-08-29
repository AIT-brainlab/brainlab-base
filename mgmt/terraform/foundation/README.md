# Foundation Module: `mgmt/terraform/foundation`

## 📌 Overview
The **Foundation** module manages the foundational cloud infrastructure and security boundaries for `ait-brainlab-mgmt`:
1. **Root IAM Governance (`iam.tf`)**: Project owners and automation service accounts.
2. **Authoritative Cloud DNS (`dns.tf`)**: Public DNS zones (`brain.cs.ait.ac.th`, `dpi.ait.ac.th`) and all static records.
3. **Secret Manager Prerequisite Vaults (`secrets.tf`)**: Cryptographic keys (`lldap-jwt`, `lldap-admin-password`, `google-oauth-client-id`, `google-oauth-client-secret`).

---

## 🔒 Security Invariants
- **Zero Secrets in Git**: `terraform.tfvars` is gitignored. All sensitive variables are marked `sensitive = true`.
- **Prevent Destroy**: Critical resources (DNS zones and secrets) have `lifecycle { prevent_destroy = true }`.
- **Remote State**: Backed by `gs://ait-brainlab-mgmt-tfstate/foundation`.

---

## 🚀 Deployment
```bash
cd mgmt/terraform/foundation
cp terraform.tfvars.example terraform.tfvars
# Fill in your values
terraform init
terraform plan
terraform apply
```
