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

### 1. Project Directory Layout Standard
All application stacks on tenant VMs are organized under `/projects/<project-name>` owned by the `ubuntu` user:

```text
/projects/
├── traefik/                # Project-Level Ingress (Port 80 -> traefik-net)
│   └── docker-compose.yml
├── print/                  # print.brain.cs.ait.ac.th
│   └── docker-compose.yml
├── example/                # example.brain.cs.ait.ac.th
│   └── docker-compose.yml
└── <my-app>/               # Your project container stack
    └── docker-compose.yml
```

### 2. Copy the Template & Configure Labels
Create your project directory under `/projects/<my-app>` and attach to the shared `traefik-net`:

```bash
mkdir -p /projects/my-app
cd /projects/my-app
```

```yaml
services:
  my-app:
    image: ghcr.io/ait-brainlab/my-app:latest
    restart: unless-stopped
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.my-app.rule=Host(`my-app.brain.cs.ait.ac.th`)"
      - "traefik.http.routers.my-app.entrypoints=web"
      - "traefik.http.services.my-app.loadbalancer.server.port=8080"
    networks:
      - traefik-net

networks:
  traefik-net:
    external: true
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
