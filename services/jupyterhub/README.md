# JupyterHub Platform Service (`services/jupyterhub`)

## Overview
AIT Brainlab operates a multi-user JupyterHub environment providing containerized, GPU-accelerated JupyterLab environments to researchers and students.

---

## 🏗 Architecture & Stack
- **Hub URL**: `https://la.cs.ait.ac.th`
- **Spawner**: Custom `DockerSpawner` dynamically mapping user UIDs/GIDs and allocating GPUs (e.g. dual NVIDIA RTX A6000) per user.
- **Storage**: User working directory lands at `/home/{username}`, mounting TrueNAS NFS `/mnt/pool-1/home/{username}` as `work`, plus FastSSD datasets.
- **Authentication**: Google OAuth2 SSO (`@ait.asia`) dynamically querying Cloud LLDAP (`brainlab-mgmt-vm:3890`) for numeric POSIX UID/GID (`2002:brainlab`).
- **Service Management**: Controlled via Docker Compose (`docker compose up -d`).

---

## 📁 Directory Structure
```
services/jupyterhub/
├── config/
│   └── jupyterhub_config.py       # Main JupyterHub Spawner & LDAP configuration
├── dockerfiles/
│   ├── default.Dockerfile         # Base data science environment
│   ├── nlp.Dockerfile             # PyTorch, Transformers, spaCy, Thai NLP
│   ├── cv.Dockerfile              # OpenCV, torchvision, Albumentations
│   └── akraradets.Dockerfile      # Customized researcher image
├── docker-compose.yml             # Traefik v3 + JupyterHub stack
└── README.md                      # Service documentation (this file)
```

---

## 🚀 Operations & Maintenance

### 1. Building a New Docker Image
```bash
cd services/jupyterhub/dockerfiles
docker build -f nlp.Dockerfile -t nlp:latest .
```

### 2. Managing JupyterHub Service
```bash
cd services/jupyterhub
docker compose ps
docker compose restart jupyterhub
docker compose logs -f jupyterhub
```

### 3. Adding New User Image to Menu
Update `image_list` in `config/jupyterhub_config.py`:
```python
image_list = {
    "default environment": "default_env",
    "NLP": "nlp",
    "Computer Vision": "cv",
    "My New Env": "custom_image_name",
}
```
