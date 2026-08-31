# NetBird WireGuard Mesh Network Architecture & Runbook

## 📌 Architecture Overview
AIT Brainlab operates a **Self-Hosted NetBird WireGuard Mesh Overlay Network** (`100.74.0.0/16`). It interconnects physical on-premise compute servers (`la`, `tokyo`), TrueNAS storage (`cairo`), the cloud management plane (`brainlab-mgmt-vm`), and remote researcher laptops.

- **Unified Control Plane**: Self-hosted on GCP Management VM at [`https://netbird.brain.cs.ait.ac.th`](https://netbird.brain.cs.ait.ac.th).
- **Identity & AuthN**: Authenticated 100% via Google OAuth2 SSO (`@ait.asia` and approved alumni `@gmail.com`).
- **Data Plane**: Direct peer-to-peer (P2P) encrypted WireGuard UDP tunnels with automatic NAT traversal (STUN/ICE). Traffic does not route through central cloud relays.

---

## 🏗️ Core Architectural Principles

### 1. Per-Node Agent Model (Every Server Joins the Mesh)
Instead of deploying a single "VPN gateway" or "subnet router" for the whole server room, **every physical server (`la`, `tokyo`, `cairo`) runs its own lightweight NetBird agent**:

```
                       ┌──────────────────────────────┐
                       │ ☁️ cloud-mgmt                │
                       │ (LLDAP :3890, NetBird :443)  │
                       └──────────────▲───────────────┘
                                      │
              WireGuard Mesh P2P      │      WireGuard Mesh P2P
        ┌─────────────────────────────┼─────────────────────────────┐
        │                             │                             │
        ▼                             ▼                             ▼
┌──────────────┐              ┌──────────────┐              ┌──────────────┐
│  🖥️ la       │              │  🖥️ tokyo    │              │  💾 cairo    │
│ (GPU Server) │              │ (GPU Server) │              │ (TrueNAS NAS)│
│ NetBird Peer │              │ NetBird Peer │              │ NetBird Peer │
└───────▲──────┘              └───────▲──────┘              └───────▲──────┘
        │                             │                             │
        └─────────────────────────────┴─────────────────────────────┘
          Physical 10Gbps CSIM Switch (Local High-Speed NFS Traffic)
```

#### Why Per-Node Mesh is Superior:
1. **Zero Single Point of Failure (SPOF)**: If `la` is being rebooted for GPU maintenance, `tokyo` and `cairo` remain 100% accessible remotely.
2. **Direct P2P Bandwidth**: Remote SSH and Jupyter sessions connect directly to the destination node via WireGuard without hairpinned middleman hops.
3. **Least-Privilege Security (Micro-Segmentation)**: You can grant students compute access to GPU servers (`la:2222`, `tokyo:2222`) while keeping TrueNAS admin consoles (`cairo:443`) restricted strictly to SysAdmins.
4. **Zero Device Limits**: Because we self-host our NetBird control plane, device limits do not apply (unlimited peers at $0 cost).

---

### 2. Multi-Site & Multi-Cloud Naming Scheme (Composable 2-Tag Model)
Do **not** create separate VPN meshes for individual services (e.g. an "NFS mesh" or "LDAP mesh"). A single physical machine is simultaneously an NFS client, an LDAP client, and a GPU runner.

Furthermore, do **not** bake every detail into monolithic group names (like `onprem-csim-gpu-servers`). NetBird allows a single peer to belong to **multiple groups simultaneously**.

We use a **Composable 2-Tag Model**: Every peer is tagged with its **Location (`loc-*`)** and its **Role/Tier (`tier-*`)**:

```
                     ┌──────────────────────────────────────────────┐
                     │           NETBIRD PEER TAGGING               │
                     └──────────────────────┬───────────────────────┘
                                            │
               ┌────────────────────────────┴────────────────────────────┐
               ▼                                                         ▼
     📍 LOCATION TAGS                                          ⚙️ ROLE / TIER TAGS
  (Where does the box sit?)                                 (What permissions does it need?)
  • loc-onprem-csim   (CSIM Server Room)                     • tier-servers   (Compute & NAS nodes)
  • loc-onprem-lab    (Brainlab Room / Lab)                  • tier-mgmt      (GCP Control Plane)
  • loc-cloud-gcp     (Google Cloud)                         • tier-operators (SysAdmin Laptops)
  • loc-cloud-aws     (Amazon Web Services)                  • tier-students  (Student Laptops)
```

#### Standard Group Taxonomy:

| Group Name | Tag Type | Purpose & Scope | Target Devices / Members |
| :--- | :---: | :--- | :--- |
| **`loc-onprem-csim`** | **Location** | Physical CSIM Server Room rack (10GbE LAN). | `la`, `tokyo`, `cairo` |
| **`loc-onprem-lab`** | **Location** | Physical workstations in the Brainlab student room. | Interactive lab desktop workstations |
| **`loc-cloud-gcp`** | **Location** | Google Cloud Platform instances. | `brainlab-mgmt-vm`, GCP Spot GPU VMs |
| **`loc-cloud-aws`** | **Location** | Amazon Web Services instances. | AWS research grant EC2 / GPU nodes |
| **`tier-servers`** | **Role** | All backend compute, GPU, and storage servers. | `la`, `tokyo`, `cairo`, cloud GPU VMs |
| **`tier-storage`** | **Role** | Central network-attached storage. | `cairo` (TrueNAS NFS / SMB) |
| **`tier-mgmt`** | **Role** | Management control plane services. | `brainlab-mgmt-vm` (LLDAP, NetBird) |
| **`tier-operators`** | **Role** | Infrastructure administrators. | Laptops of `akraradets`, `phue`, `bci` |
| **`tier-students`** | **Role** | Lab researchers and students. | Student personal laptops |

#### Standard Peer Hostname Conventions:
When peers register with NetBird, enforce standard hostnames:
1. **On-Premise Physical Servers**: Use memorable **City Names** in lowercase:
   - `la` (GPU compute node)
   - `tokyo` (GPU compute node)
   - `cairo` (TrueNAS NFS storage)
   - *Future nodes*: `paris`, `oslo`, `berlin`, `kyoto`
2. **Cloud GPU Instances**: Use structured provider identifiers:
   - `gpu-gcp-<id>` (e.g. `gpu-gcp-01`, `gpu-gcp-a100`)
   - `gpu-aws-<id>` (e.g. `gpu-aws-01`, `gpu-aws-h100`)
3. **Management Control Plane**:
   - `mgmt-vm` (or `brainlab-mgmt-vm`)
4. **User & Admin Laptops**:
   - `laptop-<username>` (e.g. `laptop-akraradets`, `laptop-phue`, `laptop-st123456`)

---

### 3. Physical 10GbE LAN vs. NetBird Mesh Tunneling
A vital performance rule for physical lab infrastructure:

> [!IMPORTANT]
> **Heavy on-prem NFS traffic stays on the physical LAN!**  
> `la`, `tokyo`, and `cairo` are connected to a physical 10Gbps CSIM Ethernet switch. NFS mounts between servers in the rack use local private IPs (`192.41.170.x`) to achieve full 10Gbps throughput with zero CPU encryption overhead.  
> **NetBird WireGuard is used for:**
> - Remote access from off-campus (students and sysadmins at home).
> - Cross-cloud connections (GCP Cloud GPU VMs to on-prem TrueNAS).
> - Encrypted LDAP queries from on-prem servers to Cloud LLDAP (`:3890`).

---

## 🔒 Access Control Policies & Software-Defined Networks (Zero-Trust)

Managed declaratively via [`mgmt/vpn/network.yaml`](file:///Users/akraradets/Projects/AIT-brainlab/brainlab-base/mgmt/vpn/network.yaml) and synchronized via [`mgmt/vpn/sync_netbird.py`](file:///Users/akraradets/Projects/AIT-brainlab/brainlab-base/mgmt/vpn/sync_netbird.py):

### A. Access Policies (Peer-to-Peer Zero-Trust)
| Policy Name | Source Group | Destination Group | Direction | Allowed Ports | Purpose |
| :--- | :--- | :--- | :---: | :--- | :--- |
| **`SysAdmin-Infra-Access`** | `sysadmin` | `brainlab-cluster`<br>`mgmt-cluster`<br>`sysadmin` | `<->` | ALL | Full SSH, Web GUIs, TrueNAS, container gateways, and routed LAN resources. |
| **`Brainlab-Cluster-Mesh`** | `brainlab-cluster` | `brainlab-cluster` | `<->` | ALL | Server-to-server interconnectivity between on-prem nodes (`la` & `cairo`). |
| **`LDAP-Directory-Access`** | `brainlab-cluster` | `mgmt-cluster` | `->` | ALL (`:3890`) | Linux SSSD and TrueNAS query Cloud LLDAP over encrypted WireGuard. |
| **`DLMS-Server-Access`** | `prj-dlms-users` | `prj-dlms-servers` | `<->` | ALL | Research team access to DLMS application server. |

### B. Software-Defined Networks (Subnet Gateways & LAN Resources)
| Network Name | Routing Peers (HA) | Resources / Targets | Authorized Groups | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **`csim-infrastructure`** | `cairo`, `la` (HA Pair) | `192.41.170.19/32` (Proxmox)<br>`192.41.170.4/32` (Cairo LAN)<br>`192.41.170.85/32` (LA LAN) | `sysadmin` | Access to CSIM hypervisors and direct server LAN IPs without exposing publicly. |
| **`dlms-cctv`** | `dsai2` | `192.168.1.2/32` (Camera 1)<br>`192.168.1.3/32` (Camera 2) | `prj-dlms-users`<br>`prj-dlms-servers` | Pull RTSP video camera streams over encrypted WireGuard tunnel. |

---

## 🚀 Server Onboarding SOP (Headless Nodes)

Headless servers cannot open a web browser for interactive Google SSO. They authenticate using dynamic **Setup Keys**.

### Step 1: Generate an Ephemeral Setup Key
1. Log in to [`https://netbird.brain.cs.ait.ac.th`](https://netbird.brain.cs.ait.ac.th) as `brainlab@ait.asia`.
2. Go to **Setup Keys** $\rightarrow$ **Add Setup Key** (or use declarative GitOps in `mgmt/vpn/network.yaml`).
3. Copy the generated key.

### Step 2: Install & Connect NetBird Agent on Ubuntu Server
Run directly on the server (`la`, `tokyo`, or `cairo`):

```bash
# 1. Install official NetBird package
curl -fsSL https://pkgs.netbird.io/install.sh | sh

# 2. For on-prem nodes behind CSIM Squid proxy (la, cairo), start the proxy tunnel:
sudo systemctl enable --now netbird-proxy-tunnel.service

# 3. Connect to the self-hosted management server
sudo netbird up \
  --management-url https://netbird.brain.cs.ait.ac.th \
  --setup-key <YOUR_SETUP_KEY>
```

NetBird registers as a systemd service (`netbird.service`) that automatically starts on boot and reconnects after network disruptions.

---

## 🔍 Verification & Health Checks

```bash
# 1. Check client connection and assigned WireGuard IP
netbird status

# Expected Output:
# Management: Connected to https://netbird.brain.cs.ait.ac.th:443
# Signal: Connected to https://netbird.brain.cs.ait.ac.th:443
# Relays: Available
# Nameservers: Available
# NetBird IP: 100.74.X.Y/16
# Interface type: Kernel (wt0) or Userspace
# Peers count: N/N Connected

# 2. Check peer details and verify DIRECT P2P connection (ICE)
netbird status -d

# Look for:
# Peer: tokyo (100.66.X.Z)
#   Connection type: P2P (Direct WireGuard)
#   Latency: 0.8ms

# 3. Test ping to another mesh peer
ping -c 3 100.66.X.Z
```

---

## 🖨️ Subnet Routers: When to Use Network Routes
If the lab has "dumb" hardware devices that **cannot run software agents** (e.g., the CSIM physical network printer `192.41.170.x` or Dell iDRAC / HP iLO management cards):

1. Pick one stable server (e.g. `cairo` or `tokyo`) to act as a **Routing Peer**.
2. In NetBird Dashboard, navigate to **Network Routes** $\rightarrow$ **Add Route**.
3. Specify:
   - **Network Range**: e.g., `192.41.170.25/32` (Single printer IP) or `192.41.170.0/24`.
   - **Routing Peer**: Select `cairo`.
   - **Distribution Groups**: Select `sysadmin-devices` (or `students` for printing).
4. On the routing server, ensure IP forwarding is enabled:
   ```bash
   sudo sysctl -w net.ipv4.ip_forward=1
   ```
