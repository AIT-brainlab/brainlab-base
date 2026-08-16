# Docker Engine & Proxy Configuration

## Overview
Docker powers the JupyterHub isolated execution environments and local microservices.

---

## 1. Docker Engine Installation
Install using Docker's official automated setup script:

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

---

## 2. Docker Daemon Proxy Configuration

Docker daemon requires proxy configuration to pull images from Docker Hub behind the CSIM firewall.

### Step 1: Create systemd drop-in directory
```bash
sudo mkdir -p /etc/systemd/system/docker.service.d
```

### Step 2: Create `/etc/systemd/system/docker.service.d/http-proxy.conf`
```ini
[Service]
Environment="HTTP_PROXY=http://192.41.170.23:3128"
Environment="HTTPS_PROXY=http://192.41.170.23:3128"
Environment="NO_PROXY=localhost,127.0.0.1,192.41.170.0/24,*.ait.ac.th,*.ait.asia"
```

### Step 3: Reload & Restart Docker
```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```

---

## 3. Storage Data Root Configuration
To avoid filling the OS root partition with Docker images, configure `/data/docker`:

Edit `/etc/docker/daemon.json`:
```json
{
  "data-root": "/data/docker"
}
```
Restart Docker:
```bash
sudo systemctl restart docker
```
