# JupyterHub Platform Service (`services/jupyterhub`)

## Overview
AIT Brainlab operates a multi-user JupyterHub environment providing containerized, GPU-accelerated JupyterLab environments to researchers and students.

---

## 🏗 Architecture & Stack
- **Hub URL**: `https://la.cs.ait.ac.th` (or `https://hub.brain.cs.ait.ac.th`)
- **Spawner**: Custom `DockerSpawner` dynamically mapping user UIDs/GIDs and allocating GPUs per user.
- **Storage**: User home directories mounted live from `/mnt/HDD/home/{username}/work`.
- **Authentication**: OpenLDAP / `lldap` or Google OIDC.
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
