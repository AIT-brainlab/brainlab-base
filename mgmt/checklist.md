# Management Plane Operations & Next Steps Roadmap (`mgmt/`)

**Architecture Version**: 2.1 (Proxmox Shared Application VM, Web Print & DLMS Integration)  
**Status Legend**: 🔴 Planned / Not Started | 🟡 In Progress | 🟢 Completed | 🔵 Verified Live

---

## 🏛️ Verified Production Baseline (Completed Milestones)

The cloud management plane (`ait-brainlab-mgmt`) has completed all foundational migration milestones and operates in steady state:

| Layer | Architecture Component | Live State | Verification Summary |
| :--- | :--- | :---: | :--- |
| **Foundation** | `mgmt/terraform/foundation/` | 🔵 | Authoritative Cloud DNS (`brain.cs.ait.ac.th`, `dpi.ait.ac.th`), IAM governance, Secret Manager prerequisite keys (`lldap-jwt`, `lldap-admin-password`, Google OAuth credentials). |
| **VM Engine** | `mgmt/terraform/vm/` | 🔵 | Disposable `e2-micro` VM with dynamic public IP auto-bound to Cloud DNS. Traefik v3 edge proxy (Let's Encrypt TLS), LLDAP, NetBird dashboard, Signal, and Management. Automated 6-hourly GCS SQLite snapshots. |
| **Identity GitOps** | `mgmt/identity/` | 🔵 | Declarative `members.yaml` (33 members) synchronized via GraphQL (`sync_users.py`). Unified GID `2002:brainlab`, Multi-Email Bindings, dedicated `ldapservice` service account (`:3890`). |
| **VPN Networks** | `mgmt/vpn/` | 🔵 | Declarative NetBird network (`network.yaml` + `sync_netbird.py`). High-Availability Subnet Gateways across CSIM 10GbE LAN (`cairo` + `la`), DLMS network, and MagicDNS CNAME for locked-down admin endpoints. Added `csim-printers` network group (`banyan`, `ricoh`, `magnum`). |
| **Core Compute** | Physical Server `la` | 🔵 | Dual RTX A6000 JupyterHub (`https://la.cs.ait.ac.th`) with Google OAuth2 AuthN, LLDAP AuthZ, TrueNAS NFS `/mnt/pool-1/home` direct mounts, 1TB iSCSI `/mnt/docker-root`, SSSD client standardization (`groupOfNames`). Legacy `slapd` decommissioned. |
| **Retired Compute** | Physical Server `tokyo` | ⚪ | **Retired / Decommissioned**. Compute workloads consolidated on `la` and cloud Spot GPUs. |
| **Print POC & Spooler** | LPD Engine (`192.41.170.5`) | 🔵 | Physical test page successfully printed to CSIM Lobby **Ricoh IM C2000** over NetBird mesh via `banyan.cs.ait.ac.th:515` using RFC 1179 LPD protocol with automatic CSIM student quota attribution (`Pst121413`). |
| **Print Service Code** | `services/printing/` | 🟢 | Full production codebase drafted: FastAPI app, Google OAuth2 SSO, `members.yaml` student ID resolver, pure-Python LPD client, 10× color quota guardrail, and Tailwind drag-and-drop UI. |

---

## 🎯 What's Next: Upcoming Deliverables & Service Roadmap

```mermaid
flowchart TD
    subgraph PHASE1 ["🖥️ Milestone 1: Proxmox Multi-Tenant VM & Governance"]
        P1A["1.1 Provision VM on Proxmox VE<br/>(192.41.170.19 on CSIM LAN)"]
        P1B["1.2 Dual-Group NetBird Enrollment<br/>(prj-dlms-servers + brainlab-cluster)"]
        P1C["1.3 Grant DLMS Researchers Access<br/>(prj-dlms-users full deploy access)"]
        P1D["1.4 Configure Proxmox Google OIDC Realm<br/>(PVE GUI SSO & Role Mapping)"]
        P1A --> P1B --> P1C
        P1A --> P1D
    end

    subgraph PHASE2 ["🖨️ Milestone 2: Web Print Service Deployment"]
        P2A["2.1 Deploy services/printing/ Stack<br/>(Run container on Proxmox VM)"]
        P2B["2.2 Configure Traefik Ingress Routing<br/>(print.brain.cs.ait.ac.th Let's Encrypt TLS)"]
        P2C["2.3 E2E Print Validation<br/>(Web upload to Ricoh & HP Magnum)"]
        P2A --> P2B --> P2C
    end

    subgraph PHASE3 ["🚗 Milestone 3: DLMS Project Workload Deployment"]
        P3A["3.1 Handover VM Access to DLMS Team<br/>(Docker / K3s environment ready)"]
        P3B["3.2 Deploy DLMS Applications & DBs<br/>(Connect to on-prem RTSP CCTV feeds)"]
        P3A --> P3B
    end

    subgraph PHASE4 ["🛡️ Milestone 4: Day-2 Automation & Maintenance"]
        P4A["4.1 Ansible Day-1 Playbooks<br/>(mgmt/ansible/ automated rollouts)"]
        P4B["4.2 Disaster Recovery Smoke Tests<br/>(Automated GCS restore test)"]
        P4C["4.3 NetBird Annual PAT Rotation<br/>(Monitored by monthly GitHub Action)"]
    end

    PHASE1 --> PHASE2
    PHASE1 --> PHASE3
    PHASE2 --> PHASE4
    PHASE3 --> PHASE4
```
---

## 📋 Actionable Task Matrix

### 🖥️ 1. Proxmox Multi-Tenant Application VM & Hypervisor Governance

| Task ID | Task Description | Owner | Priority | Status | Details / Deliverable |
| :--- | :--- | :---: | :---: | :---: | :--- |
| `NEXT-1.1` | **Provision Application VM on Proxmox VE** | Akraradet | P1 | 🟡 | Created `onprem/terraform/proxmox/` IaC module (`bpg/proxmox` provider) for Cloud-Init VM provisioning on CSIM LAN (`192.41.170.19`). |
| `NEXT-1.2` | **Dual-Group NetBird Mesh Enrollment** | Akraradet | P1 | 🔴 | Enroll the VM into NetBird with tags **`prj-dlms-servers`** and **`brainlab-cluster`** using setup key `dlms-server-enrollment`. |
| `NEXT-1.3` | **Enable DLMS Team Access & Container Runtime** | Akraradet | P1 | 🔴 | Install Docker Engine + Compose (or K3s). Ensure researchers in **`prj-dlms-users`** have SSH/deployment access to host DLMS apps. |
| `NEXT-1.4` | **Configure Proxmox Google OIDC SSO Realm** | Akraradet | P2 | 🔴 | Register `https://192.41.170.19:8006/oauth2/callback` in GCP OAuth Console. Configure Google OpenID Connect (OIDC) realm in Proxmox VE (`pveum realm add google --type openid`), set default role `NoAccess`, and map SysAdmin `@ait.asia` accounts to `Administrator` / `PVEAdmin`. |

---

### 🖨️ 2. Remote Web Print Service Production Rollout (`services/printing/`)

| Task ID | Task Description | Owner | Priority | Status | Details / Deliverable |
| :--- | :--- | :---: | :---: | :---: | :--- |
| `NEXT-2.1` | **Draft Web Print Service Codebase** | Akraradet | P1 | 🟢 | Completed: FastAPI backend, pure-Python RFC 1179 LPD spooler, Google OAuth2, members.yaml student ID mapping, 10× color warning. |
| `NEXT-2.2` | **Deploy Web Print on Proxmox Application VM** | Akraradet | P1 | 🔴 | Deploy `services/printing/docker-compose.yml` on the new Proxmox VM listening on port 8080. |
| `NEXT-2.3` | **Expose `print.brain.cs.ait.ac.th` via Traefik Edge** | Akraradet | P1 | 🔴 | Configure Traefik on `brainlab-mgmt-vm` to route `print.brain.cs.ait.ac.th` over NetBird WireGuard mesh to the Proxmox VM. |
| `NEXT-2.4` | **End-to-End Web Print Verification** | Akraradet | P1 | 🔴 | Submit test PDF from external browser via Google login to Ricoh (Lobby) and HP Magnum (Room 212); verify quota accounting. |

---

### 🚗 3. DLMS Project Workload Deployment

| Task ID | Task Description | Owner | Priority | Status | Details / Deliverable |
| :--- | :--- | :---: | :---: | :---: | :--- |
| `NEXT-3.1` | **Hand over Environment to DLMS Researchers** | Akraradet | P2 | 🔴 | Confirm members in `prj-dlms-users` (`oakaugustine@gmail.com`, `ppthwe99@gmail.com`, `ephoney1141@gmail.com`) can connect via NetBird. |
| `NEXT-3.2` | **Deploy DLMS Application Containers** | DLMS Team | P2 | 🔴 | Deploy backend API, database, and RTSP stream ingest containers bridging to cameras `192.168.1.2` and `192.168.1.3`. |

---

### 🛡️ 4. Day-2 Automation & Maintenance

| Task ID | Task Description | Owner | Priority | Status | Details / Deliverable |
| :--- | :--- | :---: | :--- | :---: | :--- |
| `NEXT-4.1` | **Complete Ansible Host Enrollment Playbooks** | Akraradet | P2 | 🟡 | Finalize `mgmt/ansible/enroll_netbird.yml` for automated zero-touch provisioning of Proxmox VMs and future nodes. |
| `NEXT-4.2` | **Disaster Recovery GCS Restore Smoke Test** | Akraradet | P3 | 🔴 | Script a sandbox test that restores `users.db` and `store.db` from `gs://ait-brainlab-mgmt-tfstate/backups/`. |
| `NEXT-4.3` | **Annual NetBird PAT Rotation Monitoring** | Whole Team | P3 | 🟢 | Monitored by `.github/workflows/netbird_pat_reminder.yml` (runs 1st of every month; triggers alert 30 days before expiration). |
