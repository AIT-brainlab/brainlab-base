# 🚀 Web Application Deployment Template (`services/template/`)

> **Official AIT Brainlab Deployment Template**: Standard boilerplate for deploying web applications, research demos, and APIs on tenant VMs (`dlms-server`, `brainlab-services`, `tokyo`) with Project-Level Traefik (HTTP Port 80) and SSL offloaded at the Edge Proxy (`brainlab-proxy` @ `192.41.170.39`).

---

## 🏗️ Architecture Overview (Two-Tier Routing Model)

1. **Edge SSL Termination (`brainlab-proxy`)**:
   - `brainlab-proxy` terminates public Let's Encrypt SSL/TLS on port 443 for `*.brain.cs.ait.ac.th`.
   - Traefik hot-reloads dynamic routes from `/opt/brainlab/traefik/dynamic/routes.yaml` (managed via Terraform `var.proxy_routes`).
   - Forwards plain HTTP requests to the target tenant VM on internal SDN NAT (`10.10.250.x:80` or `10.10.20.x:80`) or NetBird IP (`100.x.x.x:80`).

2. **Project-Level Ingress (`dlms-server`, etc.)**:
   - Tenant VM runs its own lightweight Traefik container listening **strictly on port 80** (`--entrypoints.web.address=:80`).
   - Project Traefik routes requests to internal containers (`frontend`, `backend`, `streamer`) using local Docker labels (`traefik.http.routers.<app>.rule=PathPrefix(...)`).
   - Developers have 100% autonomy over their project routes with zero SSL configuration complexity.

---

## 🛠️ Deploying Application Services on Tenant VMs

### 1. Copy the Template
Copy `services/template/docker-compose.yml` to your project folder on the VM:

```bash
mkdir -p /home/ubuntu/my-project
cp docker-compose.yml /home/ubuntu/my-project/
cd /home/ubuntu/my-project/
```

### 2. Configure Service Labels
Define routing rules using standard Docker labels:

```yaml
services:
  traefik:
    image: traefik:v3.7
    container_name: app-traefik
    restart: unless-stopped
    command:
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
    ports:
      - "80:80"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
    networks:
      - app-net

  frontend:
    image: my-frontend:latest
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.frontend.rule=PathPrefix(`/`)"
      - "traefik.http.routers.frontend.entrypoints=web"
      - "traefik.http.services.frontend.loadbalancer.server.port=3000"
    networks:
      - app-net

  backend:
    image: my-backend:latest
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.backend.rule=PathPrefix(`/api`)"
      - "traefik.http.routers.backend.entrypoints=web"
      - "traefik.http.services.backend.loadbalancer.server.port=8000"
    networks:
      - app-net
```

### 3. Deploy Stack
On the tenant VM:

```bash
docker compose up -d
```

### 4. Register Route in Terraform (`onprem/proxmox/terraform/vms/`)
In `variables.tf` (or `terraform.tfvars`):

```hcl
proxy_routes = {
  my-app = {
    domain     = "my-app.brain.cs.ait.ac.th"
    target_url = "http://10.10.250.1:80" # Target VM SDN IP or NetBird IP
  }
}
```

Run `terraform apply` to register the new domain on `brainlab-proxy` instantly with zero downtime.
