# 🚀 Research Project Developer Quickstart Guide (5-Minute Onboarding)

> **Target Audience**: Research Project Teams, Student Developers & Lab Members  
> **Server Hostname**: `<project>-server` | **SSH User**: `deploy` | **App Root**: `/projects/<project>/`  

---

## 📦 1. What You Receive From Lab Admin

When your research project is provisioned, the Lab SysAdmin provides you with:
1. **🌐 Domain**: `https://<project>.brain.cs.ait.ac.th` (and wildcards `https://*.<project>.brain.cs.ait.ac.th`)
2. **🖥️ VM Hostname**: `<project>-server`
3. **🔑 SSH Deploy Key**: `deploy-<project>` (private key for user `deploy`)
4. **📡 NetBird VPN Access**: Added to group `prj-<project>-users` via your `@ait.asia` Google account.

---

## 📡 2. Connect to NetBird VPN

All server access, database ports, and development endpoints are secured inside the NetBird WireGuard mesh:

1. Download and install NetBird from [netbird.io](https://netbird.io/).
2. Click **Sign in** and authenticate with your **`@ait.asia`** Google Account.
3. Verify connection in your terminal:
   ```bash
   netbird status
   ```

---

## 🔑 3. SSH into Your Project Server

1. Save your private key to `~/.ssh/deploy-<project>` and enforce permissions:
   ```bash
   chmod 600 ~/.ssh/deploy-<project>
   ```

2. Add a shortcut to your `~/.ssh/config`:
   ```ssh-config
   Host <project>-server
     HostName <project>-server
     User deploy
     IdentityFile ~/.ssh/deploy-<project>
     IdentitiesOnly yes
   ```

3. Connect to your server:
   ```bash
   ssh <project>-server
   ```

---

## 🐳 4. Deploy Applications (`/projects/<project>/`)

Every VM includes a pre-configured, zero-touch Traefik ingress that handles HTTPS and Let's Encrypt certificates automatically.

### Directory Standard:
```text
/projects/
├── traefik/            # ⚠️ Managed by Lab (DO NOT EDIT)
└── <project>/          # 🚀 Your Application Workspace
    ├── docker-compose.yml
    └── .env
```

### Production `docker-compose.yml` Template:

```yaml
services:
  # --------------------------------------------------------
  # 1. Frontend Web App (Next.js / React / Vue / Static)
  # --------------------------------------------------------
  frontend:
    image: ghcr.io/<your-org>/<project>-frontend:latest
    container_name: <project>-frontend
    restart: unless-stopped
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.<project>-frontend.rule=Host(`<project>.brain.cs.ait.ac.th`)"
      - "traefik.http.routers.<project>-frontend.entrypoints=web"
      - "traefik.http.services.<project>-frontend.loadbalancer.server.port=3000"
    networks:
      - traefik-net

  # --------------------------------------------------------
  # 2. Backend REST API / AI Model Server (FastAPI / Node / PyTorch)
  # --------------------------------------------------------
  backend:
    image: ghcr.io/<your-org>/<project>-backend:latest
    container_name: <project>-backend
    restart: unless-stopped
    environment:
      - DATABASE_URL=postgresql://user:secret@postgres:5432/<project>_db
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.<project>-backend.rule=Host(`api.<project>.brain.cs.ait.ac.th`)"
      - "traefik.http.routers.<project>-backend.entrypoints=web"
      - "traefik.http.services.<project>-backend.loadbalancer.server.port=8000"
    networks:
      - traefik-net
    depends_on:
      - postgres

  # --------------------------------------------------------
  # 3. Database (PostgreSQL / MySQL / Redis)
  # --------------------------------------------------------
  postgres:
    image: postgres:16-alpine
    container_name: <project>-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: <project>_db
      POSTGRES_USER: user
      POSTGRES_PASSWORD: secret
    ports:
      # Expose to NetBird mesh so developers can connect from laptop
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - traefik-net

volumes:
  postgres_data:

networks:
  traefik-net:
    external: true
```

### Start Your App:
```bash
cd /projects/<project>
docker compose pull
docker compose up -d
docker compose ps
```

Your app is immediately live with HTTPS at `https://<project>.brain.cs.ait.ac.th` and `https://api.<project>.brain.cs.ait.ac.th`!

---

## 🤖 5. Automated CI/CD (GitHub Actions)

To automatically deploy when you push to `main`:

### 1. Add Secrets to Your GitHub Repository
In your GitHub Repo $\rightarrow$ **Settings** $\rightarrow$ **Secrets and variables** $\rightarrow$ **Actions**:
* **`NETBIRD_CI_SETUP_KEY`**: Provided by Lab Admin (joins group `prj-<project>-cicd`).
* **`VM_SSH_PRIVATE_KEY`**: Your `deploy-<project>` private key.

### 2. Add `.github/workflows/deploy.yml`

```yaml
name: 🚀 Deploy Application

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Connect to NetBird VPN Mesh
        uses: netbirdio/netbird-action@v1
        with:
          setup-key: ${{ secrets.NETBIRD_CI_SETUP_KEY }}

      - name: Copy Compose Config to Server
        uses: appleboy/scp-action@v0.1.7
        with:
          host: <project>-server
          username: deploy
          key: ${{ secrets.VM_SSH_PRIVATE_KEY }}
          target: /projects/<project>
          source: 'docker-compose.yml'

      - name: Pull Images & Restart Containers
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: <project>-server
          username: deploy
          key: ${{ secrets.VM_SSH_PRIVATE_KEY }}
          script: |
            cd /projects/<project>
            echo "${{ secrets.GITHUB_TOKEN }}" | docker login ghcr.io -u ${{ github.actor }} --password-stdin
            docker compose pull
            docker compose up -d --remove-orphans
            docker compose ps
```

---

## 🗄️ 6. Connecting to Your Database from Laptop

While connected to NetBird VPN, connect your favorite database GUI (DBeaver, TablePlus, DataGrip):
* **Host**: `<project>-server`
* **Port**: `5432` (PostgreSQL) / `3306` (MySQL)
* **User**: `user`
* **Password**: `secret`
* **Database**: `<project>_db`

---

## 🆘 Quick Troubleshooting

| Issue | Quick Fix |
| :--- | :--- |
| **`Permission denied (publickey)`** | Verify you are using `ssh deploy@<project>-server` with key `deploy-<project>`. |
| **`Could not resolve hostname`** | Ensure NetBird VPN is running and shows `Connected`. |
| **`502 Bad Gateway` on domain** | Run `docker compose ps` on server to verify your container is up and port matches `loadbalancer.server.port`. |
| **Need Help?** | Contact Lab Infrastructure: `brainlab@ait.asia` |

