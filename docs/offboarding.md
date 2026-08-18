# 📋 Member Offboarding & Data Archiving Runbook

> **AIT Brainlab Modern Offboarding & Archiving SOP**  
> Covers data preservation on TrueNAS NFS, Google OAuth2 access revocation, and GitOps user archiving in `identity/users.tf`.

---

## 🎯 Offboarding Overview

Because AIT Brainlab uses **Google OAuth2 SSO** and **Identity-as-Code (`identity/users.tf`)**, member offboarding is fast, safe, and automated:

1. **Institutional Deactivation**: When AIT IT deactivates the graduating student's `@ait.asia` Google account, their access to **NetBird VPN**, **JupyterHub**, and **Web Print** is **instantly revoked by Google** with zero manual intervention.
2. **Alumni Transition**: If the member continues as an external collaborator, their account is transitioned to an approved personal email in `identity/users.tf` with the `"alumni"` group.

---

## 📋 Step-by-Step Offboarding SOP

### Step 1: Data Preservation & TrueNAS Archiving
1. Notify the researcher 30 days prior to graduation to transfer code, models, and datasets.
2. Create a timestamped archive of their work directory on TrueNAS NFS (`cairo`):
   ```bash
   sudo tar -czvf /mnt/HDD/archive/<username>_$(date +%Y%m%d).tar.gz /mnt/HDD/home/<username>/work
   ```
3. Set the archive permissions to read-only for lab preservation:
   ```bash
   sudo chmod 400 /mnt/HDD/archive/<username>_*.tar.gz
   ```

---

### Step 2: Archive or Remove Identity in GitOps (`identity/users.tf`)

#### Scenario A: Retain as Alumni / External Collaborator
If the member transitions to alumni status:
1. Open [`mgmt/terraform/identity/users.tf`](file:///Users/akraradets/Projects/AIT-brainlab/brainlab-base/mgmt/terraform/identity/users.tf).
2. Change their email to their personal address and update groups to `["member", "alumni"]`:
   ```hcl
   "johndoe" = {
     email      = "johndoe@gmail.com"
     first_name = "John"
     last_name  = "Doe"
     uid        = 123456
     gid        = 10001
     home       = "/mnt/HDD/home/johndoe"
     shell      = "/bin/bash"
     groups     = ["member", "alumni"]
   }
   ```
3. Run `terraform apply` in `mgmt/terraform/identity/`.

#### Scenario B: Complete Account Removal
If the member has left permanently:
1. Remove their user block from `users` in [`mgmt/terraform/identity/users.tf`](file:///Users/akraradets/Projects/AIT-brainlab/brainlab-base/mgmt/terraform/identity/users.tf).
2. Run `terraform apply` in `mgmt/terraform/identity/` to cleanly remove the account from LLDAP.

---

### Step 3: Revoke NetBird VPN Mesh Access
1. Open the NetBird Web Dashboard at [`https://netbird.brain.cs.ait.ac.th`](https://netbird.brain.cs.ait.ac.th).
2. Navigate to **Users** $\rightarrow$ find the offboarded member $\rightarrow$ select **Delete User** or **Block**.
3. In **Peers**, delete any registered laptops/devices belonging to the offboarded user.

---

### Step 4: Clean Up Compute Containers
On the GPU compute servers (`la`, `tokyo`):
```bash
# Terminate and remove any running JupyterHub single-user container:
docker ps -a | grep jupyter-<username> | awk '{print $1}' | xargs -r docker rm -f
```
