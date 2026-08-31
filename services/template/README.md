# 🚀 Docker Swarm Web Application Deployment Template (`services/template/`)

> **Official AIT Brainlab Deployment Template**: Standard boilerplate for deploying web applications, research demos, and APIs on the multi-node `brainlab-mesh` overlay network auto-discovered by `brainlab-proxy` (`192.41.170.39`).

---

## 📌 Day-1 Swarm Cluster Setup SOP (Manual Governance)

### 1. Initialize Swarm Manager on `brainlab-proxy` (VM 100)
Run once on `brainlab-proxy`:

```bash
docker swarm init --advertise-addr 192.41.170.39
docker network create --driver overlay --attachable brainlab-mesh
```

### 2. Join Worker Nodes (`dlms-server`, etc.)
Get worker join token from `brainlab-proxy` (`docker swarm join-token worker`) and run on the worker VM:

```bash
docker swarm join --token <WORKER_JOIN_TOKEN> 192.41.170.39:2377
```

---

## 🛠️ Deploying Application Services

### 1. Copy the Template
Copy `services/template/docker-compose.yml` to your project folder or application server.

### 2. Customize Swarm Service Labels
Update domain rules in `docker-compose.yml`:

```yaml
deploy:
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.<app-name>.rule=Host(`<app-name>.brain.cs.ait.ac.th`)"
    - "traefik.http.routers.<app-name>.entrypoints=web"
    - "traefik.http.services.<app-name>.loadbalancer.server.port=80"
```

### 3. Deploy Stack onto Swarm
On the Swarm Manager (`brainlab-proxy`), run:

```bash
docker stack deploy -c docker-compose.yml <app-name>-stack
```

---

## 🔍 Benefits of Swarm Overlay Architecture
- **Zero Exposed Host Ports**: Worker VMs do NOT expose host ports.
- **Native Service Discovery**: Traefik routes directly to container VIPs across the encrypted `brainlab-mesh` overlay.
- **Manual Governance**: Prevents split-brain cluster states during VM reprovisioning.
