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

### Step 2: Configure Composable Device Groups

NetBird allows peers to belong to multiple groups simultaneously. We use a **Composable 2-Tag Model** (`loc-*` for physical/cloud location, and `tier-*` for operational role):

1. In the left navigation, click **Access Control** $\rightarrow$ **Groups**.
2. Click **Add Group** and create the standard lab taxonomy:

| Group Name | Tag Type | Purpose & Scope | Target Devices / Auto-Assign |
| :--- | :---: | :--- | :--- |
| **`loc-onprem-csim`** | **Location** | CSIM Server Room physical hardware. | Assigned via Setup Key for `la`, `tokyo`, `cairo` |
| **`loc-onprem-lab`** | **Location** | Interactive lab desktop workstations. | Workstations in Brainlab student room |
| **`loc-cloud-gcp`** | **Location** | Google Cloud Platform instances. | `brainlab-mgmt-vm`, GCP Spot GPU VMs |
| **`loc-cloud-aws`** | **Location** | Amazon Web Services instances. | AWS research grant EC2 / GPU nodes |
| **`tier-servers`** | **Role** | All GPU and NAS servers across all locations. | All compute and storage nodes |
| **`tier-mgmt`** | **Role** | Control plane management services. | `brainlab-mgmt-vm` |
| **`tier-operators`** | **Role** | SysAdmin laptops (full god-mode). | Auto-assign: `brainlab@ait.asia`, `st121413@ait.asia` |
| **`tier-students`** | **Role** | General researcher & student laptops. | Auto-assign: Default for `@ait.asia` users |

---

### Step 3: Configure Zero-Trust Access Policies

By default, NetBird creates an "All-to-All" rule. Replace it with **least-privilege Zero-Trust policies**:

1. Navigate to **Access Control** $\rightarrow$ **Policies**.
2. **Disable or Delete** the default `All` rule.
3. Create the following **4 clean policies**:

#### Policy 1: Server Cluster Interconnect
- **Name**: `Servers-Cluster-Mesh`
- **Sources**: `tier-servers`
- **Destinations**: `tier-servers`
- **Direction**: Bidirectional (`<->`)
- **Protocol**: ALL (TCP/UDP/ICMP)
- *Rationale*: Allows GPU nodes to communicate for distributed PyTorch/MPI training and mount TrueNAS NFS.

#### Policy 2: SysAdmin Infrastructure Access
- **Name**: `SysAdmin-Infra-Access`
- **Sources**: `sysadmin`
- **Destinations**: `brainlab-cluster`, `mgmt-cluster`, `sysadmin`
- **Direction**: Bidirectional (`<->`)
- **Protocol**: ALL
- *Rationale*: Grants sysadmins unrestricted root SSH (port 22), TrueNAS Web Admin, Proxmox VE, IPMI/iDRAC, and remote management.

#### Policy 3: Cluster Mesh
- **Name**: `Brainlab-Cluster-Mesh`
- **Sources**: `brainlab-cluster`
- **Destinations**: `brainlab-cluster`
- **Direction**: Bidirectional (`<->`)
- **Protocol**: ALL
- *Rationale*: Allows on-prem GPU and storage nodes (`la` & `cairo`) to communicate for distributed PyTorch/MPI training and mount TrueNAS NFS.

#### Policy 4: LDAP Directory Queries
- **Name**: `LDAP-Directory-Access`
- **Sources**: `brainlab-cluster`
- **Destinations**: `mgmt-cluster`
- **Direction**: One-way (`->`)
- **Protocol / Ports**: `TCP 3890` (LDAP)
- *Rationale*: Allows physical Linux SSSD and JupyterHub on compute servers to query LLDAP securely over WireGuard.

---

### Step 4: Generate Server Setup Keys (Day 1 Ansible)

Headless servers (`la`, `tokyo`, `cairo`) authenticate using **Setup Keys**.

1. Navigate to **Setup Keys** in the dashboard.
2. Click **Add Setup Key**.
3. Fill in:
   - **Key Name**: `onprem-csim-enrollment`
   - **Type**: **Reusable** (Expires in 24h or 7 days)
   - **Auto-assigned Groups**: Select **both**:
     - ✅ **`loc-onprem-csim`**
     - ✅ **`tier-servers`**
4. Click **Create Key** and copy the generated token string.

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
