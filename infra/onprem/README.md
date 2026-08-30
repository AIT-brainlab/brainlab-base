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
| **`tokyo.cs.ait.ac.th`** | Web APIs & Reverse Proxy | `192.41.170.x` | Service Server |
| **`cairo`** | TrueNAS Shared Storage (NFS) | `192.41.170.x` | High-Capacity NAS Arrays |
