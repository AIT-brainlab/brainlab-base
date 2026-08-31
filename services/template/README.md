# 🚀 Docker Swarm Web Application Deployment Template (`services/template/`)

> **Official AIT Brainlab Deployment Template**: Standard boilerplate for deploying web applications, research demos, and APIs on Swarm worker nodes (`dlms-server`, `tokyo`, `cairo`) connected via the `brainlab-mesh` overlay network auto-discovered by `brainlab-proxy` (`192.41.170.39`).

---

## 📌 Day-1 Swarm Cluster Setup SOP (Manual Governance)

### 1. Initialize Swarm Manager on `brainlab-proxy` (VM 100)
Run once on `brainlab-proxy`:

```bash
docker swarm init --advertise-addr 192.41.170.39 --data-path-addr 100.74.188.237
docker network create --driver overlay --attachable brainlab-mesh
```

### 2. Join Worker Nodes (`dlms-server`, etc.)
Get worker join token from `brainlab-proxy` (`docker swarm join-token worker`) and run on the worker VM:

```bash
docker swarm join --token <WORKER_JOIN_TOKEN> --data-path-addr <WORKER_NETBIRD_IP> 192.41.170.39:2377
```

---

## 🛠️ Deploying Application Services on Swarm Workers

### 1. Copy the Template
Copy `services/template/docker-compose.yml` to your project folder or repository.

### 2. Worker Placement Constraint (`node.role == worker`)
The template enforces execution on worker nodes so heavy research workloads never run on `brainlab-proxy`:

```yaml
deploy:
  placement:
    constraints:
      - node.role == worker  # Schedule strictly on worker nodes (e.g. dlms-server)
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.<app-name>.rule=Host(`<app-name>.brain.cs.ait.ac.th`)"
    - "traefik.http.routers.<app-name>.entrypoints=web"
    - "traefik.http.services.<app-name>.loadbalancer.server.port=80"
```

### 3. Deploy Stack from Swarm Manager (`brainlab-proxy`)
On the Swarm Manager (`brainlab-proxy`), run:

```bash
docker stack deploy -c docker-compose.yml <app-name>-stack
```

---

## 🔍 Key Architecture Invariants
- **Strict Worker Placement**: `node.role == worker` guarantees workloads land on research VMs, leaving `brainlab-proxy` dedicated to Traefik edge routing.
- **Zero Exposed Host Ports**: Containers communicate over the encrypted `brainlab-mesh` overlay without host port binding.
- **NetBird Data Path**: `--data-path-addr` routes Swarm overlay VXLAN tunnels directly over encrypted WireGuard mesh P2P links.
