# NVIDIA GPU Drivers & Container Toolkit Setup

## Overview
AIT Brainlab servers utilize NVIDIA GPUs for machine learning and deep learning workloads. This runbook details driver and container runtime installation.

---

## 1. NVIDIA Driver Installation

### Method A: Automated CLI Driver Installation (Recommended)
```bash
sudo apt update
sudo apt install -y ubuntu-drivers-common
sudo ubuntu-drivers install --gpgpu
```

### Method B: Specific Version via Ubuntu PPA
```bash
sudo add-apt-repository ppa:graphics-drivers/ppa -y
sudo apt update
sudo apt install -y nvidia-driver-535
```

### Verification
Reboot the machine, then verify GPU status:
```bash
sudo reboot
nvidia-smi
```

---

## 2. NVIDIA Container Toolkit (Docker GPU Support)

To allow Docker containers (such as JupyterHub user sessions) to access GPUs:

### Step 1: Add NVIDIA Package Repositories
```bash
distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
  && curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
     sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
     sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
```

### Step 2: Install Toolkit
```bash
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
```

### Step 3: Configure Docker Daemon Runtime
Edit `/etc/docker/daemon.json`:
```json
{
  "data-root": "/data/docker",
  "runtimes": {
    "nvidia": {
      "path": "nvidia-container-runtime",
      "runtimeArgs": []
    }
  }
}
```

### Step 4: Restart Docker & Test
```bash
sudo systemctl restart docker
# Run quick GPU test container
docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi
```
