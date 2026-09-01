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
- **Read-Only Query Service Account (`ldapservice`)**: Downstream services (Linux SSSD on `la`, `cairo`, TrueNAS, and JupyterHub) authenticate queries using a dedicated `ldapservice` account in group `lldap_strict_readonly`. Password lives in GCP Secret Manager (`lldap-readonly-password`). Created in post-deployment GitOps, **never in Terraform**.
- **Multi-Email Binding**: A single POSIX user record (`username`, numeric `UID`, `GID`, home path `/mnt/pool-1/home/<username>`) can bind multiple authorized emails (e.g. `stXXXXXX@ait.asia` + `user@gmail.com`) for seamless alumni/graduate continuation without data copying or `chown`.
- **Zero Internal TLS Overhead**: All internal LDAP communication across TrueNAS, Linux SSSD, and Ubuntu Desktops runs through the NetBird WireGuard encrypted mesh tunnel (`ldap://` on port `:3890` with `ldap_id_use_start_tls = false`). No self-signed certificates or Python `ldap3` package hacks.

### 3. Service Admin Domain (`services/`)
- **JupyterHub (`services/jupyterhub/`)**: Multi-user hub using `DockerSpawner` mapping user UIDs/GIDs and allocating GPUs with environments (`default`, `nlp`, `cv`).
- **Web Printing Service (`services/printing/` or `print.brain.cs.ait.ac.th`)**: Remote web print portal (`docker-cups`) bridging cloud uploads to on-prem CSIM printer over NetBird WireGuard mesh.

### 4. Operational Runbooks & Infrastructure Knowledge Base (`docs/`)
- **Infrastructure & Server Runbooks (`docs/infra/`)**: Physical server installation (`onprem/`), GPU drivers, TrueNAS NFS/iSCSI, SSSD, network topology (`network/`), and cloud templates (`cloud/`).
- **Operational SOPs (`docs/`)**: Member onboarding (`onboarding.md`), offboarding (`offboarding.md`), troubleshooting (`troubleshooting.md`), and roles matrix (`roles_and_responsibilities.md`).

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
│   ├── checklist.md               # Master next steps & deliverables checklist
│   ├── oauth_setup.md             # Google OAuth2 & OIDC console setup SOP
│   ├── identity/                  # Declarative members.yaml & GraphQL user sync
│   ├── vpn/                       # Declarative network.yaml & NetBird GitOps sync
│   └── terraform/                 # Modular Terraform IaC (foundation, vm)
│
├── services/                      # 🚀 Service Admin Domain
│   ├── jupyterhub/                # Spawner config, Dockerfiles (default, nlp, cv)
│   └── printing/                  # Web Print portal (docker-cups)
│
├── docs/                          # 📋 Operational SOPs & Infrastructure Runbooks
│   ├── infra/                     # Hardware, OS, GPU, TrueNAS, SSSD, and Network runbooks
│   │   ├── onprem/                # Ubuntu OS, CUDA, NFS, iSCSI, SSSD, and bootstrap script
│   │   ├── network/               # CSIM proxy, NetBird VPN, and DNS topology
│   │   └── cloud/                 # Research workload templates (Spot GPUs, GCS)
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
20. **Single-Port Container SSH Gateway**: Compute node (`la`) provides direct SSH access into user Jupyter containers via a single host gateway port (e.g. `2222`) using OpenSSH `ForceCommand docker exec -it -u %u jupyter-%u /bin/bash`. Never allocate or store per-student port numbers (`jupyterSshPort`) on host machines.
21. **Proxy Environment & Internal Network Isolation (`NO_PROXY` Invariant)**: Containers and edge proxies that require outbound HTTP proxy configuration (`HTTP_PROXY`/`HTTPS_PROXY` targeting institutional forward proxies like Squid `http://192.41.170.82:3128`) MUST explicitly set `NO_PROXY` covering `localhost`, `127.0.0.1`, internal Docker service names, local subnets (`172.16.0.0/12`, `10.0.0.0/8`), and the NetBird WireGuard overlay (`100.103.0.0/16`, `*.brain.cs.ait.ac.th`). Failing to set `NO_PROXY` causes edge proxies and application runtimes to route internal backend traffic through Squid, resulting in infinite redirect loops (HTTP 308) and unreachable container backends.
22. **Zero Internal TLS for Mesh-Internal Services & Web GUIs**: Internal administration consoles (such as TrueNAS SCALE Web GUI) running on physical infrastructure behind institutional firewalls do NOT terminate TLS or issue public ACME certificates. They run plain HTTP (port 80) and are accessed exclusively through NetBird WireGuard overlay / MagicDNS (`http://cairo:80`). WireGuard provides cryptographic confidentiality and authentication at Layer 3 (ChaCha20-Poly1305), eliminating certificate expiration, proxy middleman failure modes, and self-signed browser warnings.
23. **JupyterHub Spawner Hook Standards & Working Directory Architecture**:
    - In `dockerspawner.DockerSpawner`, container environment injection and volume mounting MUST be registered via `c.Spawner.pre_spawn_hook` (or `Authenticator.pre_spawn_start`), never as uncalled methods inside the Spawner subclass.
    - User default working directory MUST land at `/home/{username}` (not `/home/{username}/work`), allowing researchers to see their TrueNAS NFS home (`work`), shared FastSSD storage (`Dataset`), and archive storage (`dataset_arch`) side-by-side in JupyterLab's file navigator.
    - Pre-spawn hooks must robustly fall back to direct LLDAP lookups by `spawner.user.name` matching either `mail` or `uid` (`(&(objectClass=posixAccount)(|(mail={identifier})(uid={identifier})))`) to ensure container spawn never fails even if session `auth_state` is missing or unencrypted in the Hub database.
24. **NetBird DataStoreEncryptionKey & Configuration Persistence**: In self-hosted NetBird control plane deployments, `management.json` containing the active `DataStoreEncryptionKey` MUST be backed up to GCS alongside `store.db` (via `/opt/brainlab/scripts/backup_to_gcs.sh`) and restored prior to container initialization. If a clean control plane reset is performed, purging `store.db` permits the first Google OIDC user to register automatically as the Master Account Owner without manual database intervention.
25. **Institutional Forward Proxy Tunnel & Egress IP Redirection**: On-premise nodes behind forward institutional proxies (Squid `192.41.170.82:3128`) route NetBird management traffic through a local CONNECT tunnel (`netbird-proxy-tunnel.service`) and `iptables` NAT redirection (`netbird-iptables.sh`). When the management public IP or domain changes, `netbird-proxy-tunnel.service` must be restarted to update the dynamic NAT destination. Bootstrap scripts downloaded from GitHub raw URLs during migrations MUST specify the commit hash or a cache-busting query parameter (`?v=$(date +%s)`) to prevent executing stale cached CDN code.
26. **Operator Device Group Assignment & Lazy WireGuard Tunnel Activation**: Personal operator workstations authenticating via Google OIDC MUST be assigned to the `sysadmin` group (via user `auto_groups` or peer settings) to inherit administrative access under `SysAdmin-Infra-Access`. NetBird client status displaying `0/N Connected` under `Lazy connection: true` is standard power-saving idle behavior; WireGuard peer-to-peer tunnels awaken instantaneously upon transmission of active network traffic.
27. **TrueNAS Background Task Execution & `noexec` /tmp Invariant**: When dispatching long-running maintenance tasks (such as recursive `chown`/`chmod` across `/mnt/pool-1/home`) on TrueNAS SCALE, never use backgrounded `sudo` in interactive shells (`sudo nohup ... &`), which aborts with exit code `0x57f` upon TTY detachment. Additionally, `/tmp` on TrueNAS is mounted with the `noexec` security flag (`status=203/EXEC`). Always dispatch detached background tasks using `sudo systemd-run -u <unit-name> /bin/bash <script_path>` and monitor via `journalctl -u <unit-name> -f`.
28. **SSSD Client RFC2307bis Group Resolution & Enumeration**: When configuring Linux SSSD clients against LLDAP, group memberships are stored as Distinguished Names (DNs) under `groupOfNames` (`member`) or `groupOfUniqueNames` (`uniqueMember`). SSSD MUST configure `ldap_schema = rfc2307bis`, `ldap_group_object_class = groupOfNames`, and `ldap_group_member = member`. In directories where all users share a unified primary POSIX GID (`2002:brainlab`), `enumerate = true` MUST be enabled so SSSD pre-caches all user DN mappings on startup, preventing glibc `getent group` serialization failures (`error writing group entry: Invalid argument`).
29. **NetBird Windows Client Setup Keys & Subnet Routing Peers**:
    - **Setup Key vs. PSK**: In NetBird client installations on Windows, setup keys are UUID strings containing hyphens (`-`). They must strictly be passed to `--setup-key` (or the "Setup Key" GUI input), never to `--preshared-key` or the WireGuard Pre-Shared Key field, which triggers base64 decoding failures (`illegal base64 data at input byte 8`).
    - **Subnet Routing (Routing Peers)**: When configuring a Windows NetBird peer as a subnet router (e.g. bridging physical on-prem devices like CCTV IP cameras) with `masquerade: true`, Windows requires IP forwarding explicitly enabled across its network interfaces via PowerShell `Set-NetIPInterface -Forwarding Enabled` and registry `Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "IPEnableRouter" -Value 1`.
30. **TrueNAS Persistent iSCSI Mount Standards**: Compute nodes mounting dedicated block storage volumes from TrueNAS over iSCSI (such as `/mnt/docker-root`) must enable automatic node login via `iscsiadm -m node -T <target> -p <ip>:3260 --op=update -n node.startup -v automatic`, and declare `_netdev` in `/etc/fstab` (`rw,suid,_netdev,exec,auto...`) to ensure systemd defers mounting until the network stack and `open-iscsi` initiator are active.
31. **Canonical Domain Name Taxonomy & Anti-Drift Invariant**: AI assistants and documentation templates MUST NOT invent or reference hypothetical subdomains like `auth.brain.cs.ait.ac.th`, `authen.brain.cs.ait.ac.th`, or `hub.brain.cs.ait.ac.th`. The lab domain taxonomy is strictly partitioned as:
    - **`ldap.brain.cs.ait.ac.th`**: LLDAP Web Administration Portal (`https://`, port 443) and encrypted WireGuard POSIX directory query endpoint (`ldap://`, port 3890).
    - **`netbird.brain.cs.ait.ac.th`**: NetBird Dashboard, Management REST API, and Signal gRPC (`https://`, port 443 via Traefik `h2c`).
    - **`la.cs.ait.ac.th`**: Production multi-user GPU JupyterHub platform running on physical server `la` (dual RTX A6000).
    - **`ml.brain.cs.ait.ac.th`** / **`*.ml.brain.cs.ait.ac.th`**: MLflow experiment tracking server and deployed research demonstration APIs running on on-prem node `tokyo`.
    - **`print.brain.cs.ait.ac.th`**: Remote Web Print Portal bridging cloud uploads to the CSIM physical printer.

32. **Modern NetBird Software-Defined Networks & High-Availability Subnet Gateways**:
    - Lab subnet routing MUST use NetBird's modern `networks` architecture (v0.25+) declared in `mgmt/vpn/network.yaml` rather than legacy standalone `/routes`.
    - Routing peers inside physical subnets (such as `cairo` and `la` on the 10GbE CSIM LAN `192.41.170.0/24`) MUST be configured as a multi-peer HA router group with `masquerade: true`. NetBird automatically provides zero-downtime failover between gateways.
    - Resources within Networks must assign authorized client groups directly under `groups:` (e.g. `groups: [sysadmin]`), ensuring only permitted peers receive kernel routes.
33. **NetBird Zero-Trust Policy Destination Group Invariant for Routed Resources**:
    - In NetBird, defining a Network Resource with an authorized group (e.g. `groups: [sysadmin]`) distributes the route to the client's kernel table, but NetBird's WireGuard firewall will SILENTLY DROP TCP SYN packets unless an active Access Policy explicitly permits the destination.
    - Therefore, access policies for operator groups (such as `SysAdmin-Infra-Access`) MUST include the operator group itself in `destinations` (e.g. `sources: [sysadmin]` $\rightarrow$ `destinations: [brainlab-cluster, mgmt-cluster, sysadmin]`) so WireGuard permits connections to network resources tagged with that group.
34. **Mesh-Only Web Administration via Dynamic MagicDNS CNAME**:
    - When internal web interfaces (such as LLDAP Web Admin) require valid Let's Encrypt SSL while being restricted to WireGuard peers via Traefik IP allowlisting (`100.64.0.0/10`), the domain MUST NOT be overridden with hardcoded WireGuard IPs.
    - Instead, declare a NetBird internal DNS zone with a dynamic `CNAME` targeting the host peer's MagicDNS FQDN (e.g. `ldap.brain.cs.ait.ac.th` $\rightarrow$ `brainlab-mgmt-vm.netbird.selfhosted.`). This ensures valid TLS handshakes while remaining 100% immune to WireGuard IP rotations or VM reprovisioning.

35. **Proxmox systemd-boot ESP Maintenance**:
    - Proxmox hypervisors running `systemd-boot` store kernel images and initramfs directly within `/boot/efi/<machine-id>/<version>/`.
    - Automated kernel updates that encounter `No space left on device` on `/boot/efi` MUST NOT delete the currently active running kernel (`uname -r`). Safely remove 2-3 older non-running versions directly from `/boot/efi/<machine-id>/`, resume with `dpkg --configure -a`, and finalize with `apt autoremove --purge -y`.
36. **Proxmox `bpg/proxmox` Provider SSH Node Mapping & Agent Timeout Invariant**:
    - When configuring the `bpg/proxmox` Terraform provider, if the target node hostname (e.g. `proxmox`) is not resolvable via DNS, the `provider "proxmox"` block MUST explicitly declare `ssh { node { name = var.target_node, address = "192.41.170.19" } }`.
    - All `proxmox_virtual_environment_vm` resources MUST set `agent { enabled = true, timeout = "1s" }` to prevent state refresh execution hangs when `qemu-guest-agent` is uninitialized.
37. **On-Premise Traefik Dynamic File Provider & Edge SSL Offloading Invariant**:
    - On-premise edge proxy (`brainlab-proxy` at `192.41.170.39`) terminates public Let's Encrypt SSL/TLS on port 443 and auto-reloads upstream reverse proxy routing using Traefik's dynamic file provider (`--providers.file.directory=/etc/traefik/dynamic` with `watch=true`).
    - Routes are declared in Terraform via `var.proxy_routes` (`onprem/proxmox/terraform/vms/routes.tf`), forwarding plain HTTP traffic directly to tenant VM internal SDN IPs (`10.10.250.x:80` / `10.10.20.x:80`) or NetBird IPs (`100.x.x.x:80`).
    - Tenant application containers running on separate VMs (`dlms-server`, `brainlab-services`, `tokyo`) run project-level Traefik or web services listening **strictly on plain HTTP port 80** (`entrypoints=web`), eliminating insecure remote TCP Docker sockets (`:2375`), Docker Swarm overlay overhead, and duplicate internal TLS certificates.
38. **Proxmox Out-of-Band Purge & Terraform State Synchronization Invariant**:
    - If a Proxmox virtual machine is purged or destroyed out-of-band via `qm destroy <vmid>`, `terraform state rm proxmox_virtual_environment_vm.<name>` MUST be executed before re-running `terraform apply` to prevent HTTP 500 state drift errors (`unable to create VM <vmid> - VM <vmid> already exists`).
39. **On-Premise GCS Remote State Partitioning Invariant**:
    - On-premise Proxmox Terraform modules MUST persist remote state in `gs://ait-brainlab-mgmt-tfstate` under dedicated `onprem/proxmox/` prefixes (`onprem/proxmox/foundation` for host governance and `onprem/proxmox/vms` for tenant application VMs).

---

## 📝 Code & Documentation Standards
- **File Naming**: Use `snake_case.md` for all documentation and configuration templates.
- **Markdown Notes**: Format all documentation in clean, Obsidian-compatible GitHub Flavored Markdown (supporting wikilinks `[[page]]` and standard markdown links).
- **Preserve Existing Configurations**: Maintain comments and docstrings in existing configurations.
