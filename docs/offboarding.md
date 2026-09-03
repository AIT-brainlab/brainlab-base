# 📋 Member Offboarding & Data Archiving Runbook

> **AIT Brainlab Modern Offboarding & Archiving SOP**  
> Covers data preservation on TrueNAS NFS, Google OAuth2 access revocation, and GitOps user archiving in `mgmt/identity/members.yaml`.

---

## 🎯 Offboarding Overview

Because AIT Brainlab uses **Google OAuth2 SSO** and **Declarative Identity-as-Code (`mgmt/identity/members.yaml`)**, member offboarding is fast, safe, and automated:

1. **Institutional Deactivation & Compute Revocation**: When AIT IT deactivates the graduating student's `@ait.asia` Google account, their access to **JupyterHub GPU compute** and active VPN sessions is **instantly revoked by Google**. JupyterHub authorizes strictly against `primary_email`, preventing unauthorized GPU compute utilization.
2. **Alumni Transition & Data Preservation**: If the member continues as an external collaborator, their personal email is added to `secondary_emails` in `mgmt/identity/members.yaml` (Multi-Email Binding), preserving their existing POSIX UID and TrueNAS files without copying data. *(Note: If an alumni is explicitly authorized to continue GPU compute, update their `primary_email` to their personal email).*

---

## 📋 Step-by-Step Offboarding SOP

### Step 1: Data Preservation & TrueNAS Archiving
1. Notify the researcher 30 days prior to graduation to transfer code, models, and datasets.
2. Create a timestamped archive of their work directory on TrueNAS NFS (`cairo`):
   ```bash
   sudo tar -czvf /mnt/pool-1/archive/<username>_$(date +%Y%m%d).tar.gz /mnt/pool-1/home/<username>/work
   ```
3. Set the archive permissions to read-only for lab preservation:
   ```bash
   sudo chmod 400 /mnt/pool-1/archive/<username>_*.tar.gz
   ```

---

### Step 2: Archive or Remove Identity in GitOps (`mgmt/identity/members.yaml`)

#### Scenario A: Retain as Alumni / External Collaborator
If the member transitions to alumni status:
1. Open [`mgmt/identity/members.yaml`](../mgmt/identity/members.yaml).
2. Add their approved personal email under `secondary_emails` (for identity preservation and Web Print) or promote it to `primary_email` if they are granted active GPU compute access:
   ```yaml
   - username: johndoe
     display_name: "John Doe"
     primary_email: st123456@ait.asia       # Or 'johndoe@gmail.com' if active JupyterHub GPU compute is approved
     secondary_emails:
       - johndoe@gmail.com                  # Preserves POSIX mapping & Web Print
     uid: 123456
     gid: 2002
     home_directory: /mnt/pool-1/home/johndoe
     login_shell: /bin/bash
     groups: [brainlab]
   ```
3. Run `python3 mgmt/identity/sync_users.py --apply`.

#### Scenario B: Complete Account Removal
If the member has left permanently:
1. Remove their entry from `members` in [`mgmt/identity/members.yaml`](../mgmt/identity/members.yaml).
2. Run `python3 mgmt/identity/sync_users.py --apply` to cleanly archive the account from LLDAP.

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
