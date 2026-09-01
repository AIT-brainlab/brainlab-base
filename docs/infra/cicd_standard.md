# 🚀 AIT Brainlab Per-Project CI/CD & Ingress Standard (`docs/infra/cicd_standard.md`)

> **Master Guide for Lab Services**: Standard operating procedure and architectural specification for deploying, routing, and continuously delivering applications across AIT Brainlab infrastructure.

---

## 🏛️ The Two Independent Lifecycles

In AIT Brainlab, launching and maintaining a web service involves **two completely decoupled lifecycles**:

```mermaid
flowchart TD
    subgraph LIFECYCLE1 ["🛡️ Lifecycle 1: Ingress Provisioning & Teardown (Infra Admin / GitOps)"]
        L1_URL["1. Choose Public Domain<br/>(e.g., app.brain.cs.ait.ac.th)"]
        L1_DNS["2. Provision Cloud DNS A Record<br/>(mgmt/terraform/foundation/dns.tf -> 192.41.170.39)"]
        L1_PROXY["3. Provision Edge Traefik Route<br/>(onprem/proxmox/terraform/vms/variables.tf -> proxy_routes)"]
        L1_APPLY["4. Run `terraform apply`<br/>(Edge acquires Let's Encrypt SSL & routes to VM)"]
        L1_URL --> L1_DNS --> L1_PROXY --> L1_APPLY
    end

    subgraph LIFECYCLE2 ["🚀 Lifecycle 2: Per-Project Application CI/CD (Developers / GitHub Actions)"]
        L2_CODE["1. Code Push to main branch"]
        L2_TEST["2. Automated Lint & Tests (Pytest / Jest)"]
        L2_BUILD["3. Docker Buildx -> Push to ghcr.io/ait-brainlab/<app>"]
        L2_DEPLOY["4. Deploy to Target On-Prem VM (over NetBird Mesh)"]
        L2_VERIFY["5. Health Check & Live Verification"]
        L2_CODE --> L2_TEST --> L2_BUILD --> L2_DEPLOY --> L2_VERIFY
    end

    LIFECYCLE1 -.->|"Prerequisite: Public URL & SSL Active"| LIFECYCLE2
```

---

## 🛡️ Lifecycle 1: Ingress Provisioning & Teardown Guide

Before a project's CI/CD can expose a web interface to clients, its URL must be registered in **two critical places**:

### Step 1: Place 1 — Google Cloud DNS (`mgmt/terraform/foundation/dns.tf`)
Every public domain must have an authoritative `A` record pointing to the Edge Proxy (`brainlab-proxy` @ `192.41.170.39`):

```hcl
# In mgmt/terraform/foundation/dns.tf
locals {
  brainlab_records = {
    # Add your project subdomain here:
    "my_app" = { name = "my-app.brain.cs.ait.ac.th.", ip = "192.41.170.39", ttl = 300 }
  }
}
```

> [!IMPORTANT]
> **ACME Pre-Validation Invariant**: The Cloud DNS record **MUST** exist before Traefik on `brainlab-proxy` requests a Let's Encrypt certificate. If Traefik attempts validation before DNS propagates, Let's Encrypt will fail with `NXDOMAIN`.

---

### Step 2: Place 2 — Brainlab Edge Proxy Traefik (`onprem/proxmox/terraform/vms/variables.tf`)
Register the upstream mapping from the public domain to the target VM's internal IP (`10.10.250.x:80` or NetBird IP `100.74.x.x:80`):

```hcl
# In onprem/proxmox/terraform/vms/variables.tf
variable "proxy_routes" {
  default = {
    my_app = {
      domain     = "my-app.brain.cs.ait.ac.th"
      target_url = "http://10.10.250.2:80"  # Target VM internal IP (Port 80)
      aliases    = []
    }
  }
}
```

When `terraform apply` is run, Terraform writes `/opt/brainlab/traefik/dynamic/routes.yaml` on `brainlab-proxy`. Traefik automatically hot-reloads the configuration, obtains a Let's Encrypt certificate, and offloads SSL.

---

### 🛑 Ingress Teardown SOP (Decommissioning a Service)
When retiring a project:
1. Remove the service block from `var.proxy_routes` in `onprem/proxmox/terraform/vms/variables.tf`.
2. Remove the DNS record from `mgmt/terraform/foundation/dns.tf`.
3. Run `terraform apply`. Traefik instantly revokes the upstream route with zero downtime for other services.

---

## 🚀 Lifecycle 2: Per-Project Application CI/CD Standard

### 1. Container Registry Standard (`ghcr.io`)
* **Registry**: GitHub Container Registry (`ghcr.io/ait-brainlab/<project-name>`).
* **Authentication**: Native `secrets.GITHUB_TOKEN` inside GitHub Actions.
* **Tag Taxonomy**:
  * `ghcr.io/ait-brainlab/<project>:sha-<commit_sha>` (Immutable trace)
  * `ghcr.io/ait-brainlab/<project>:latest` (Current production release)

---

### 2. On-Premise Target VM Deployment
The GitHub Action runner securely reaches the on-premise Proxmox VM behind CSIM firewalls using **NetBird WireGuard Mesh Action**:

1. Runner joins NetBird mesh using `secrets.NETBIRD_CI_SETUP_KEY` (tagged in group `ci-cd-runners`).
2. Runner connects via SSH (`appleboy/ssh-action`) directly to the VM's NetBird IP (`100.74.x.x`).
3. Executes zero-downtime rolling pull and restart:
   ```bash
   echo "${{ secrets.GITHUB_TOKEN }}" | docker login ghcr.io -u ${{ github.actor }} --password-stdin
   docker compose pull
   docker compose up -d --remove-orphans
   ```
4. Validates container health check via `curl -f http://localhost:80`.

---

## 📦 Starter GitHub Actions Workflow (`.github/workflows/deploy.yml`)

Drop this standard workflow file into your project repository:

```yaml
name: 🚀 Build & Deploy Service

on:
  push:
    branches: [main]
  workflow_dispatch:

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  # 1. Quality Checks & Unit Testing
  lint-and-test:
    name: 🧪 Lint & Test
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Run Tests
        run: |
          if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
          if [ -f requirements-dev.txt ]; then pip install -r requirements-dev.txt; fi
          if [ -d tests ]; then pytest tests/; fi

  # 2. Build & Push Container to GHCR
  build-and-push:
    name: 🐳 Build & Push Image
    needs: lint-and-test
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract Docker Metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=raw,value=latest
            type=sha,prefix=sha-,format=short

      - name: Build and Push Image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  # 3. Deploy to Target Proxmox VM over NetBird Mesh
  deploy-to-vm:
    name: 🚀 Deploy to On-Prem VM
    needs: build-and-push
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Connect to NetBird WireGuard Mesh
        uses: netbirdio/netbird-action@v1
        with:
          setup-key: ${{ secrets.NETBIRD_CI_SETUP_KEY }}

      - name: Execute Deployment on Target Host
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.TARGET_VM_NETBIRD_IP }} # e.g. 100.74.10.218
          username: ubuntu
          key: ${{ secrets.VM_SSH_PRIVATE_KEY }}
          script: |
            set -e
            cd /home/ubuntu/app

            # 1. Log in to GHCR
            echo "${{ secrets.GITHUB_TOKEN }}" | docker login ghcr.io -u ${{ github.actor }} --password-stdin

            # 2. Pull and restart containers
            docker compose pull
            docker compose up -d --remove-orphans

            # 3. Health check verification
            sleep 5
            curl -f http://localhost:80 || (echo "Deployment failed health check" && exit 1)

            echo "✔ Service deployed and healthy!"
```

---

## 🔐 Required GitHub Repository Secrets

Configure the following secrets under **Settings $\rightarrow$ Secrets and variables $\rightarrow$ Actions** in your project repository:

| Secret Name | Value / Description | Example |
| :--- | :--- | :--- |
| `NETBIRD_CI_SETUP_KEY` | NetBird setup key with group `ci-cd-runners` | `XXXX-XXXX-XXXX-XXXX` |
| `TARGET_VM_NETBIRD_IP` | NetBird WireGuard IP of target VM | `100.74.10.218` |
| `VM_SSH_PRIVATE_KEY` | SSH private key for `ubuntu` user | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `APP_SECRETS` (Optional) | Any project-specific production API keys | `DATABASE_URL=...` |

---

## 🌟 Core Invariants Checklist for Developers
1. **Plain HTTP Port 80 Invariant**: Local project Traefik or service must listen on **port 80** (`--entrypoints.web.address=:80`). Do **not** expose or terminate port 443 inside project containers.
2. **Squid Forward Proxy Environment**: Outbound internet requests from on-prem containers must inherit `HTTP_PROXY=http://192.41.170.82:3128` with proper `NO_PROXY` bypass rules for internal subnets (`10.0.0.0/8`, `192.41.170.0/24`, `100.64.0.0/10`, `*.brain.cs.ait.ac.th`).
3. **Two-Tier Separation**: Changing project routing labels inside `docker-compose.yml` does not require touching `brainlab-proxy` or Cloud DNS.
4. **Single Source of Truth for Member Identity (`members.yaml`)**: Services must **never** maintain duplicate local copies or volume-mounted copies of `members.yaml`. They must fetch directly from the canonical URL `https://raw.githubusercontent.com/AIT-brainlab/brainlab-base/main/mgmt/identity/members.yaml` on startup, run a background cron-like auto-sync on the 1st of every month at 00:00 ICT, and provide a manual refresh endpoint / UI button (`POST /api/members/refresh`).
