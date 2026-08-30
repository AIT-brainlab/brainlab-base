# On-Premise Infrastructure Runbooks (`infra/onprem`)

Welcome to the **On-Premise Infrastructure** administration hub. These guides provide step-by-step Standard Operating Procedures (SOPs) for provisioning, configuring, and maintaining physical servers, GPU compute nodes, and shared storage in the AIT Brainlab.

---

## 📚 Runbooks Index

| Guide | Description | Key Target Files / Ports |
| :--- | :--- | :--- |
| [**1. OS Setup**](os_setup.md) | Ubuntu 22.04 LTS installation, partitioning, and locale | `/etc/locale.gen`, `/etc/hosts` |
| [**2. Network & Proxy**](network_proxy.md) | CSIM proxy (`192.41.170.82:3128`) & NTP time sync | `/etc/environment`, `/etc/systemd/timesyncd.conf` |
| [**3. NVIDIA GPUs**](nvidia_gpu.md) | CUDA drivers & NVIDIA Container Toolkit runtime | `nvidia-smi`, `/etc/docker/daemon.json` |
| [**4. TrueNAS Storage**](truenas_nfs.md) | Central NFS home directory mount (`/mnt/pool-1/home`) | `/etc/fstab` (`cairo:/mnt/pool-1/home`) |
| [**5. Docker Engine**](docker_setup.md) | Docker daemon installation, proxying, and storage root | `/etc/systemd/system/docker.service.d/` |

---

## 🖥️ Physical Lab Server Inventory

| Hostname | Role | IP Address | Primary Hardware |
| :--- | :--- | :--- | :--- |
| **`la.cs.ait.ac.th`** | Primary GPU Compute Node & JupyterHub | `192.41.170.85` | Multi-GPU Workstation |
| **`tokyo.cs.ait.ac.th`** | Web APIs & Reverse Proxy | `192.41.170.86` | Service Server |
| **`cairo`** | TrueNAS Shared Storage (NFS) | `192.41.170.4` | High-Capacity NAS Arrays |

---

## ⚡ CSIM 1-Command Bootstrap & TrueNAS Post-Upgrade Reconnection

Whenever TrueNAS SCALE is upgraded, or when enrolling any physical server behind the CSIM firewall (`la`, `tokyo`, `cairo`), run this single command:

```bash
curl -fsSL https://raw.githubusercontent.com/AIT-brainlab/brainlab-base/main/infra/onprem/scripts/bootstrap_netbird_csim.sh | sudo bash
```

### What this does automatically:
1. Synchronizes clock to `Asia/Bangkok` via Squid proxy (eliminates token clock skew).
2. Resolves live Google Cloud public IP dynamically from DNS.
3. Automatically installs NetBird client if missing.
4. Auto-injects self-hosted URL (`https://netbird2.brain.cs.ait.ac.th`) into `/var/lib/netbird/default.json`.
5. Starts background Squid CONNECT tunnel on port `33443` (leaves port 443 100% free for TrueNAS Web GUI or JupyterHub).
6. Sets kernel `iptables REDIRECT` rule.
7. Connects node to NetBird WireGuard mesh and outputs `netbird status`.

*(For enrolling a specific server with its custom setup key, pass the key as argument: `sudo bash -s -- <SETUP_KEY>`)*
