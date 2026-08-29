# AIT Brainlab Base (`brainlab-base`) — AI Assistant Guidelines

## 📌 Repository Overview
This repository serves as the central knowledge base (Obsidian markdown vault), infrastructure runbook, lab service configuration directory, and hardware/asset catalog for **AIT Brainlab** (Asian Institute of Technology).

---

## 🏗 System Architecture & Key Domains

### 1. Core Management Plane (`mgmt/`) — `ait-brainlab-mgmt`
- **Purpose**: Permanent, decoupled, low-cost ($0.45-$7.45/mo), 100% Stateless GitOps management control plane.
- **Unified Control Plane VM**: Co-hosts **LLDAP** (Identity/POSIX) and **Self-Hosted NetBird** (VPN Control Plane & Signal) on a single lightweight `e2-micro` VM (< 300 MB RAM total) with automated Traefik Let's Encrypt SSL. Permanently eliminates device limits.
- **Decoupled 3-Layer Architecture**:
  1. **Foundation (`mgmt/terraform/foundation/`)**: Root IAM governance, authoritative Cloud DNS zones (`brain.cs.ait.ac.th`, `dpi.ait.ac.th`), and Secret Manager prerequisite keys (`lldap-jwt`, `lldap-admin-password`, Google OAuth credentials). [🔵 Live]
  2. **VM Engine (`mgmt/terraform/vm/`)**: Disposable Compute VM (`e2-micro`), dynamic ephemeral public IP with auto-binding Cloud DNS records (`ldap`, `netbird2`), VPC firewall, and clean 5-service Docker Compose stack (Traefik, LLDAP, NetBird Dashboard, Signal, Management). [🔵 Live]
  3. **Identity GitOps (`mgmt/identity/`)**: Declarative Identity-as-Code — `members.yaml` declaring members, numeric UIDs/GIDs, Multi-Email Bindings, and automated GraphQL synchronization (`sync_users.py`). Zero third-party Terraform providers. [🔵 Live]
  4. **Mesh Operations (`mgmt/ansible/`)**: Day 1 host and peer enrollment using ephemeral, single-use setup keys. [🟡 Staged]
- **GCS Remote State Backend**: Terraform modules use `backend "gcs"` targeting `gs://ait-brainlab-mgmt-tfstate` with prefixes `foundation` and `vm`.
- **One-Time Foundation Boundary**: GCP Project, Billing, and State Bucket are one-time prerequisites; all subsequent deployments and CI/CD assume these exist.
- **Traefik gRPC & Signal Routing**: All gRPC backends (`netbird-management`, `netbird-signal`) strictly require `traefik.http.services.<service>.loadbalancer.server.scheme=h2c`. Signal service is unified on port 443 HTTPS via Traefik router rule `Host(...) && PathPrefix('/signalexchange.SignalExchange/')` with `Proto: "https"` and `URI: "<subdomain>.<domain>:443"`.
- **GCP Hairpin NAT Loopback**: The Management VM includes `127.0.0.1 <netbird_subdomain>.<domain>` in `/etc/hosts` to allow local host containers to communicate with Traefik TLS endpoints without external NAT hairpin blockage.
- **Invariant**: **Never** provision heavy GPU compute or transient research workloads inside `ait-brainlab-mgmt`.

### 2. Identity & Access Governance (`mgmt/identity/`)
- **AuthN (Google OAuth2)**: Handles 100% of identity verification, passwords, and 2FA. Supports `@ait.asia`, `@ait.ac.th`, and approved alumni `@gmail.com`. Graduation/deactivation by AIT automatically revokes access.
- **AuthZ (LLDAP Passwordless Directory)**: LLDAP acts strictly as an authorization and POSIX mapping directory (mapping email $\rightarrow$ UID/GID/home path). LLDAP stores **NO user passwords** for human members (`NULL` password hash in database).
- **Group Governance Model**:
  - **`admin`**: Strictly reserved for the master lab service account (`bci` / `brainlab@ait.asia`).
  - **`brainlab`**: All active lab researchers, students, faculty, and graduated alumni belong to `brainlab`.
  - **Zero Alumni Group**: Eliminated in favor of Multi-Email Binding (binding personal `@gmail.com` directly to the member's persistent numeric UID).
- **Read-Only Query Service Account (`ldapservice`)**: Downstream services (Linux SSSD on `la`, `tokyo`, `cairo`, TrueNAS, and JupyterHub) authenticate queries using a dedicated `ldapservice` account in group `lldap_strict_readonly`. Password lives in GCP Secret Manager (`lldap-readonly-password`). Created in post-deployment GitOps, **never in Terraform**.
- **Multi-Email Binding**: A single POSIX user record (`username`, numeric `UID`, `GID`, home path `/mnt/pool-1/home/<username>`) can bind multiple authorized emails (e.g. `stXXXXXX@ait.asia` + `user@gmail.com`) for seamless alumni/graduate continuation without data copying or `chown`.
- **Zero Internal TLS Overhead**: All internal LDAP communication across TrueNAS, Linux SSSD, and Ubuntu Desktops runs through the NetBird WireGuard encrypted mesh tunnel (`ldap://` on port `:3890` with `ldap_id_use_start_tls = false`). No self-signed certificates or Python `ldap3` package hacks.

### 3. Infrastructure Admin Domain (`infra/`)
- **On-Premise Servers (`infra/onprem/`)**: Ubuntu 22.04 LTS servers (`la.cs.ait.ac.th`, `tokyo.cs.ait.ac.th`, `cairo`).
- **NVIDIA CUDA & Runtime**: NVIDIA driver management and Container Toolkit (`runtime: nvidia`).
- **TrueNAS Storage**: Central NFS home directory storage mounted at `/mnt/HDD/home`.
- **Institutional Proxy**: CSIM forward proxy required for outbound traffic (`http://192.41.170.23:3128`).
- **Research Cloud Workloads (`infra/cloud/`)**: Spot GPU templates, GCS buckets, and research grants ($5k Faculty / $1k PhD).
- **Network & VPN (`infra/network/`)**: NetBird mesh VPN, CSIM proxy routing, and DNS topology.

### 4. Service Admin Domain (`services/`)
- **JupyterHub (`services/jupyterhub/`)**: Multi-user hub using `DockerSpawner` mapping user UIDs/GIDs and allocating GPUs with environments (`default`, `nlp`, `cv`).
- **Identity & Access (`services/identity/`)**: `lldap` user directory, Google OAuth2 SSO, and Linux SSSD client configurations.
- **MLflow Platform (`services/mlflow/`)**: Experiment tracking server on `tokyo.cs.ait.ac.th:5000` with TrueNAS artifact storage.
- **Web Printing Service (`services/printing/` or `print.brain.cs.ait.ac.th`)**: Remote web print portal (`docker-cups`) bridging cloud uploads to on-prem CSIM printer over NetBird WireGuard mesh.
- **Web APIs & Gateway (`services/api/`)**: Traefik reverse proxy and deployed FastAPI / AI demonstration applications.

### 5. Operational Runbooks (`docs/`)
- **Onboarding (`docs/onboarding.md`)**: New member onboarding SOP.
- **Offboarding (`docs/offboarding.md`)**: Data preservation and account archiving SOP.
- **Troubleshooting (`docs/troubleshooting.md`)**: Incident troubleshooting guide.
- **Roles Matrix (`docs/roles_and_responsibilities.md`)**: Division of tasks between Infrastructure Admin and Service Admin.

---

## 📁 Repository Directory Structure

```
brainlab-base/
├── README.md                      # Central knowledge base landing page
├── AGENTS.md                      # AI Assistant context and rules (this file)
├── GEMINI.md                      # Link to AGENTS.md
│
├── mgmt/                          # 🛡️ Core Management Plane (ait-brainlab-mgmt)
│   ├── README.md                  # Control plane architecture & governance
│   ├── checklist.md               # Master migration & implementation checklist
│   ├── migration_plan.md          # Zero-downtime on-prem to cloud migration SOP
│   └── terraform/                 # Modular Terraform IaC (iam, dns, secrets, vm, identity, vpn)
│
├── infra/                         # 🛠️ Infrastructure Admin Domain
│   ├── onprem/                    # Physical nodes, OS install, GPU, TrueNAS NFS
│   ├── cloud/                     # Research workload templates (Spot GPUs, GCS, credits)
│   └── network/                   # Network routing, CSIM proxy, DNS topology
│
├── services/                      # 🚀 Service Admin Domain
│   ├── jupyterhub/                # Spawner config, Dockerfiles (default, nlp, cv)
│   ├── identity/                  # SSO, Google OAuth, SSSD templates
│   ├── mlflow/                    # MLflow experiment tracking server setup
│   └── api/                       # Traefik reverse proxy & deployed apps
│
├── docs/                          # 📋 Operational SOPs & Handover Runbooks
│   ├── onboarding.md              # Member onboarding checklist
│   ├── offboarding.md             # Account archiving SOP
│   ├── troubleshooting.md         # Incident troubleshooting guide
│   └── roles_and_responsibilities.md # Infra Admin vs Service Admin matrix
│
├── archive/                       # 📦 Archived legacy assets (old api, dockerfiles, images)
└── .obsidian/                     # Obsidian vault settings & plugins
```

---

## 🔒 Security & Safe Operating Protocols
1. **No Hardcoded Secrets**: Never commit plain-text passwords, LDAP administrative bind passwords, SSL private keys (`/etc/letsencrypt/live/`), or `JUPYTERHUB_CRYPT_KEY` values to version control.
2. **Terraform Safety**: Always apply `lifecycle { prevent_destroy = true }` on Cloud DNS zones, GCP Secret Manager keys, and permanent Static Public IPs (`google_compute_address.mgmt_ip`).
3. **Stateless Control Plane**: The Management VM is 100% disposable ("Cattle, not Pets"). Permanent user research data lives strictly on TrueNAS NFS (`/mnt/HDD/home`).
4. **Deterministic Version Pinning**: Pin all core infrastructure containers to explicit tags (`traefik:v3.7`, `lldap/lldap:2026-08-10-debian`, `netbird:0.77.0`).
5. **Standardized Timezone**: Enforce `Asia/Bangkok` (ICT / UTC+7) across the VM OS, journald, and Docker Compose `TZ` environment variables.
6. **Active Bootstrap Verification**: Use `terraform_data` with `local-exec` log streaming (`wait_for_bootstrap.sh`) to ensure `terraform apply` only completes after all containers are healthy.
7. **Human vs Server NetBird Access**: Human researchers authenticate via Google OIDC without setup keys. Headless physical servers and cloud GPU VMs use Secret Manager enrollment keys.
8. **NetBird Data Plane**: NetBird transfers (e.g. large 1TB datasets) are direct peer-to-peer (P2P) and must not be proxied through cloud relays.
9. **Decoupled 3-Layer Lifecycle**: Terraform manages strictly Day 0 infrastructure (`foundation/` for IAM/DNS/Secrets, and `vm/` for compute & Traefik/LLDAP/NetBird control plane). Identity is managed via GitOps (`mgmt/identity/members.yaml`), and VPN mesh peer enrollment is handled via Day 1 Ansible (`mgmt/ansible/`).
10. **Dynamic Single-Use Setup Keys**: Server enrollment setup keys are generated dynamically as single-use, ephemeral tokens for Ansible automation. Never store static NetBird setup keys in GCP Secret Manager or Terraform state.
11. **Single Master Debug Console (Zero UI Drift)**: In NetBird GitOps, ONLY the master lab account (`brainlab@ait.asia`) is granted `role = "admin"` for the Web Dashboard for emergency signal inspection. All personal SysAdmin accounts (`st121413`, `akraradets`, `phue`) use `role = "user"` with `auto_groups = [sysadmin-devices]`, giving personal devices full WireGuard mesh reachability while preventing accidental Web UI configuration drift.
12. **Explicit Device Group Naming**: Avoid ambiguous group names. Name physical operator hardware groups explicitly (e.g. `sysadmin-devices`) to prevent confusion between NetBird Web user roles (`role = "admin"`) and network firewall device groups.
13. **Automated Peer Enrollment & Upgrade-Aware Lifecycle**: When enrolling local peers or deploying host containers via `terraform_data` with `local-exec` (e.g. `mgmt/terraform/vpn/peer.tf`), the resource MUST explicitly bind its container image version variable (e.g. `var.netbird_client_version`) to `triggers_replace`. This guarantees that image upgrades in Terraform automatically trigger image pull, container recreation, and network interface health verification (`wt0`) without manual SSH or container drift.
14. **Zero Plain-Text Credentials on Local Disk**: Terraform providers connecting to control plane management APIs MUST read administrative credentials dynamically from GCP Secret Manager via `data.google_secret_manager_secret_version` rather than storing plain-text tokens in `.tfvars` files.
15. **Unified Edge TLS Termination for Signal & Web**: Control plane signaling and management MUST terminate TLS at Traefik on port 443 with `scheme=h2c`, eliminating exposed custom plaintext gRPC ports (`:33073`) to ensure seamless institutional proxy and firewall traversal.
16. **Automated GCS State Persistence for Control Plane Databases**: The Management VM automatically syncs SQLite databases (`store.db`, `users.db`) to `gs://<state_bucket>/backups/` every 6 hours and on system shutdown. On boot, the VM restores these databases before launching containers, ensuring instant disaster recovery and preserving NetBird PAT tokens and LLDAP POSIX attributes across VM destructions without manual intervention.
17. **Fast, Non-Throttling VM Bootstrap**: Startup scripts on burstable control plane VMs (`e2-micro`) MUST NOT run full OS upgrades (`apt upgrade -y`). They must install only required runtime packages (`docker.io`, `docker-compose-v2`, `sqlite3`, `curl`, `jq`) with `--no-install-recommends` to keep VM initialization strictly under 90 seconds.
18. **Zero Synthetic Token Injections**: Never write custom scripts that synthesize or reverse-engineer internal application database hashes (e.g. NetBird PATs). Official tokens must be generated through the application's native UI/API, saved to GCP Secret Manager, and preserved via database backups.
19. **Identity GitOps & Group Governance**:
    - **Source of Truth**: All lab members, POSIX UIDs, GIDs, and home paths are declared in `mgmt/identity/members.yaml` and synchronized via `sync_users.py`.
    - **Sole Administrator**: Only the master lab account (`bci` / `brainlab@ait.asia`) is granted `admin` membership. All other members belong strictly to `brainlab`.
    - **Multi-Email Binding (Zero Alumni Group)**: Graduated members and alumni do not use an `alumni` group. Their personal `@gmail.com` accounts are bound directly to their single persistent POSIX UID (`uidNumber`) in `members.yaml`.
    - **Read-Only Query Service Account (`ldapservice`)**: Provisioned post-deployment via `sync_users.py` in group `lldap_strict_readonly`. Password is stored in GCP Secret Manager as `lldap-readonly-password` and consumed by Linux SSSD (`/etc/sssd/sssd.conf`) and JupyterHub. Never provision `ldapservice` inside Terraform.
20. **Single-Port Container SSH Gateway**: Compute nodes (`la`, `tokyo`) provide direct SSH access into user Jupyter containers via a single host gateway port (e.g. `2222`) using OpenSSH `ForceCommand docker exec -it -u %u jupyter-%u /bin/bash`. Never allocate or store per-student port numbers (`jupyterSshPort`) on host machines.

---

## 📝 Code & Documentation Standards
- **File Naming**: Use `snake_case.md` for all documentation and configuration templates.
- **Markdown Notes**: Format all documentation in clean, Obsidian-compatible GitHub Flavored Markdown (supporting wikilinks `[[page]]` and standard markdown links).
- **Preserve Existing Configurations**: Maintain comments and docstrings in existing configurations.
