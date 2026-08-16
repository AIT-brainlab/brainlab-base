# CSIM Institutional Proxy & Firewall Rules

## Overview
All outbound network traffic from the CSIM laboratory subnet (`192.41.170.0/24`) must pass through the institutional forward proxy: `http://192.41.170.23:3128`.

---

## 1. Proxy Specification
- **Proxy Host**: `192.41.170.23`
- **Proxy Port**: `3128`
- **Supported Protocols**: HTTP, HTTPS, FTP

---

## 2. Applications Requiring Proxy Injection

| Service / Tool | Configuration Location | Example Setting |
| :--- | :--- | :--- |
| **System Shell** | `/etc/environment` | `http_proxy=http://192.41.170.23:3128` |
| **APT** | `/etc/apt/apt.conf.d/proxy.conf` | `Acquire::http::Proxy "http://192.41.170.23:3128/";` |
| **Docker Daemon** | `/etc/systemd/system/docker.service.d/http-proxy.conf` | `Environment="HTTP_PROXY=..."` |
| **Python pip** | `pip install --proxy http://192.41.170.23:3128 <pkg>` | Or via `HTTP_PROXY` env var |
| **Git CLI** | `git config --global http.proxy http://192.41.170.23:3128` | Git HTTP/HTTPS proxy |
| **JupyterHub Spawner** | `jupyterhub_config.py` | `c.Spawner.environment['http_proxy']` |
