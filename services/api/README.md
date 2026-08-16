# Web APIs & Reverse Proxy Services (`services/api`)

## Overview
This directory contains configuration for the Traefik edge reverse proxy and deployed demo applications, APIs, and microservices hosted on `tokyo.cs.ait.ac.th`.

---

## 🌐 Active Domain Routing (`services/api/domains`)

All domains routed via Traefik:
- `tokyo.cs.ait.ac.th`
- `api-chakyapi.tokyo.cs.ait.ac.th`
- `api-fastapi.tokyo.cs.ait.ac.th`
- `web-httpd.tokyo.cs.ait.ac.th`
- `web-aitgpt.tokyo.cs.ait.ac.th`
- `api-gpt2detect.tokyo.cs.ait.ac.th`
- `web-gpt2detect.tokyo.cs.ait.ac.th`
- `web-thaigovai.tokyo.cs.ait.ac.th`
- `api-rwa.tokyo.cs.ait.ac.th`

---

## 📁 Deployed Applications
- **`traefik/`**: Reverse proxy routing configurations and SSL automation.
- **`fastapi/`**: Base FastAPI microservice template and endpoints.
- **`aitgpt/`**: Web demo interface for AITGPT.
- **`gpt2detect/`**: GPT-2 generated text detection API & web interface.
- **`thaigovai/`**: Thai Government AI demonstration web app.
- **`httpd/` & `whoami/`**: Lightweight diagnostic and HTTP server services.
