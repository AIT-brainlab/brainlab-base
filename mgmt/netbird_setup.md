# 📡 Self-Hosted NetBird Configuration Runbook

> **Endpoint**: [`https://netbird2.brain.cs.ait.ac.th`](https://netbird2.brain.cs.ait.ac.th)  
> **Target Audience**: Infrastructure Administrators (`brainlab@ait.asia`, `akraradets`, `phue`)  
> **Protocol**: Zero-Trust WireGuard Mesh VPN with Google OAuth2 SSO

---

## 🎯 Quick Start Checklist

- [ ] **Step 1: First-time Login via Google SSO** (Claim Admin Ownership)
- [ ] **Step 2: Define Device Groups** (`servers`, `sysadmin-devices`, `lab-members`)
- [ ] **Step 3: Define Access Control Policies** (Zero-Trust isolation)
- [ ] **Step 4: Generate Server Setup Keys** (For Day 1 Ansible enrollment)
- [ ] **Step 5: Verify GCS Database Persistence**

---

## 📋 Step-by-Step Configuration Guide

### Step 1: Initial Login (Claiming Master Ownership)

1. Open [`https://netbird2.brain.cs.ait.ac.th`](https://netbird2.brain.cs.ait.ac.th) in your web browser.
2. Click **Continue with Google**.
3. **Log in using the master institutional account**: `brainlab@ait.asia`.
   > [!IMPORTANT]
   > The **first account** to log in automatically becomes the **Account Owner / Administrator**.  
   > By using `brainlab@ait.asia`, the master lab identity permanently retains administrative ownership.
4. Future SysAdmin logins: Personal accounts (`akraradets@gmail.com`, `st121413@ait.asia`, `phue@ait.asia`) log in with **User** role to prevent accidental Web UI configuration drift.

---

### Step 2: Configure Device Groups

NetBird uses **Groups** to categorize peers and enforce network segmentation.

1. In the left navigation, click **Access Control** $\rightarrow$ **Groups**.
2. Click **Add Group** and create the following three groups:

| Group Name | Auto-Assign Rule | Purpose |
| :--- | :--- | :--- |
| **`servers`** | *None (Assigned via Setup Key)* | Physical compute nodes (`la`, `tokyo`), TrueNAS storage (`cairo`), and cloud VMs. |
| **`sysadmin-devices`** | User: `brainlab@ait.asia`, `st121413@ait.asia` | Full mesh reachability for operator workstations and sysadmin laptops. |
| **`lab-members`** | User: `@ait.asia`, approved alumni `@gmail.com` | Student and researcher personal laptops. |

---

### Step 3: Configure Zero-Trust Access Policies

By default, NetBird creates an "All-to-All" rule. For lab security, replace it with **least-privilege Zero-Trust policies** so students cannot probe each other's laptops.

1. Navigate to **Access Control** $\rightarrow$ **Policies**.
2. **Disable or Delete** the default `All` rule.
3. Create the following **3 clean policies**:

#### Policy A: Server Interconnect (Full Mesh for Cluster Nodes)
- **Name**: `Server-Cluster-Interconnect`
- **Sources**: `servers`
- **Destinations**: `servers`
- **Direction**: Bidirectional (`<->`)
- **Protocol**: ALL (TCP/UDP/ICMP)
- *Rationale*: Allows GPU nodes to mount TrueNAS NFS (`/mnt/HDD/home`), query LLDAP (`:3890`), and execute distributed PyTorch/MPI training across servers.

#### Policy B: SysAdmin Management Access
- **Name**: `SysAdmin-Full-Access`
- **Sources**: `sysadmin-devices`
- **Destinations**: `servers`
- **Direction**: Bidirectional (`<->`)
- **Protocol**: ALL
- *Rationale*: Grants sysadmins unrestricted SSH, TrueNAS Web Admin, IPMI/iDRAC, and container debugging access from anywhere.

#### Policy C: Student & Researcher Compute Access
- **Name**: `Lab-Member-To-Compute`
- **Sources**: `lab-members`
- **Destinations**: `servers`
- **Direction**: One-way (`->`)
- **Protocol / Ports Allowed**:
  - `TCP 2222` (Single-Port Container SSH Gateway)
  - `TCP 8888` / `8000` (JupyterHub Web Portal)
  - `TCP 5000` (MLflow Experiment Tracking)
  - `TCP 631` (Web Printing Portal)
  - `ICMP` (Ping diagnostics)
- *Rationale*: Allows students to train models and connect to Jupyter containers while **completely isolating student laptops from one another**.

---

### Step 4: Generate Server Setup Keys (Day 1 Ansible)

Headless servers (`la`, `tokyo`, `cairo`) do not have web browsers for interactive Google OAuth2 login. They connect using **Setup Keys**.

1. Navigate to **Setup Keys** in the dashboard.
2. Click **Add Setup Key**.
3. Fill in:
   - **Key Name**: `servers-onboarding-key`
   - **Type**:
     - **Reusable** (Expires in 24h or 7 days) if onboarding multiple physical servers at once.
     - **One-off** (Single-use) for strict ephemeral enrollment.
   - **Auto-assigned Groups**: Select **`servers`**.
4. Click **Create Key** and copy the generated token string (`A1B2C3D4...`).

#### Manual Enrollment Test on a Physical Server:
```bash
# On Ubuntu server (la.cs.ait.ac.th / tokyo.cs.ait.ac.th):
sudo netbird up \
  --management-url https://netbird2.brain.cs.ait.ac.th \
  --setup-key <GENERATED_SETUP_KEY>
```

#### Verification:
```bash
netbird status
# Output:
# Management: Connected to https://netbird2.brain.cs.ait.ac.th:443
# Signal: Connected to https://netbird2.brain.cs.ait.ac.th:443
# IP: 100.66.X.X/16
# Interface type: Kernel (wt0)
```

---

### Step 5: Verify GCS Database Persistence

NetBird stores all groups, policies, and peer states in SQLite (`store.db`). 

To ensure your newly created groups and policies are permanently preserved across VM destructions:
1. Trigger an immediate snapshot backup:
   ```bash
   gcloud compute ssh brainlab-mgmt-vm \
     --zone=asia-southeast1-a \
     --project=ait-brainlab-mgmt \
     --tunnel-through-iap \
     --command="sudo /opt/brainlab/scripts/backup_to_gcs.sh"
   ```
2. Check GCS backup bucket:
   ```bash
   gcloud storage ls gs://ait-brainlab-mgmt-tfstate/backups/netbird/
   # Output: gs://ait-brainlab-mgmt-tfstate/backups/netbird/store.db
   ```

---

## 🔒 Security Best Practices
1. **Never Commit Setup Keys**: Setup keys should never be committed to version control. Pass them to Ansible at runtime via CLI flags (`-e netbird_setup_key=...`) or environment variables.
2. **Single Master Account**: Keep `brainlab@ait.asia` as the sole NetBird Admin to avoid configuration drift between administrators.
3. **Direct P2P Data Transfers**: NetBird creates direct WireGuard peer-to-peer tunnels. Large file transfers to TrueNAS do NOT pass through Google Cloud bandwidth, incurring $0 cloud transfer egress.
