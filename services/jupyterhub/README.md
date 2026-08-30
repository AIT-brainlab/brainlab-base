# JupyterHub Platform Service (`services/jupyterhub`)

## Overview
AIT Brainlab operates a multi-user JupyterHub environment providing containerized, GPU-accelerated JupyterLab environments to researchers and students.

---

## 🏗 Architecture & Stack
- **Hub URL**: `https://la.cs.ait.ac.th`
- **Spawner**: Custom `DockerSpawner` dynamically mapping user UIDs/GIDs and allocating GPUs (e.g. dual NVIDIA RTX A6000) per user.
- **Storage**: User working directory lands at `/home/{username}`, mounting TrueNAS NFS `/mnt/pool-1/home/{username}` as `work`, plus FastSSD datasets.
- **Authentication**: Google OAuth2 SSO (`@ait.asia`) dynamically querying Cloud LLDAP (`ldap.brain.cs.ait.ac.th:3890`) for numeric POSIX UID/GID (`2002:brainlab`).
- **Service Management**: Controlled by systemd unit (`jupyterhub.service`).

---

## 📁 Directory Structure
```
services/jupyterhub/
├── config/
│   ├── jupyterhub_config.py       # Main JupyterHub Spawner & LDAP configuration
│   └── systemd/
│       └── jupyterhub.service     # Systemd service unit for auto-boot
├── dockerfiles/
│   ├── default.Dockerfile         # Base data science environment
│   ├── nlp.Dockerfile             # PyTorch, Transformers, spaCy, Thai NLP
│   ├── cv.Dockerfile              # OpenCV, torchvision, Albumentations
│   └── akraradets.Dockerfile      # Customized researcher image
└── README.md                      # Service documentation (this file)
```

---

## 🚀 Operations & Maintenance

### 1. Building a New Docker Image
```bash
cd services/jupyterhub/dockerfiles
docker build -f nlp.Dockerfile -t nlp:latest .
```

### 2. Restarting JupyterHub Service
```bash
sudo systemctl restart jupyterhub.service
sudo journalctl -u jupyterhub.service -f
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
