# Ubuntu 22.04 LTS Installation & Base Configuration

## Overview
This runbook covers the standard OS provisioning process for new physical servers and GPU workstations at AIT Brainlab.

---

## 1. Operating System Installation
- **OS Version**: Ubuntu 22.04 LTS (Desktop or Server edition).
- **Partitioning**: Root filesystem (`/`) on local high-speed SSD/NVMe.
- **Hostname convention**:
  - `la.cs.ait.ac.th` (Primary compute)
  - `tokyo.cs.ait.ac.th` (Web services & APIs)
  - `cairo` (TrueNAS NFS storage)

---

## 2. Locale Configuration
Run the following commands to ensure UTF-8 locale consistency:

```bash
sudo apt-get install -y locales
sudo locale-gen en_US.UTF-8
sudo update-locale LC_TIME=en_US.UTF-8
```

---

## 3. Essential Administrative Packages
Install the required foundational packages:

```bash
sudo apt update
sudo apt install -y curl wget git vim build-essential software-properties-common ntpdate
```

---

## 4. Next Provisioning Steps
Once the base OS is installed, proceed in order:
1. [[network_proxy|CSIM Network & Proxy Setup]]
2. [[nvidia_gpu|NVIDIA Drivers & Container Toolkit]]
3. [[truenas_nfs|TrueNAS NFS Storage Mount]]
4. [[docker_setup|Docker & Container Runtime Setup]]
