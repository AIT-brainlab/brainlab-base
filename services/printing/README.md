# Remote Web Print Service (`services/printing`)

## 📌 Overview
The **AIT Brainlab Remote Web Print Service** (`https://print.brain.cs.ait.ac.th`) allows lab researchers and students to upload and print PDF documents to CSIM physical laboratory printers from any device, anywhere (on or off campus).

It authenticates users using **Google OAuth2 SSO** (`@ait.asia`, `@ait.ac.th`, and approved lab alumni `@gmail.com`) and automatically submits print jobs to the CSIM print server (`banyan.cs.ait.ac.th:515`) using the RFC 1179 LPD protocol, attributing quota deduction directly to the student's CSIM account.

---

## 🏗️ Architecture & Stack

```
[ Researcher / Student Browser ]
               │  HTTPS (443)
               ▼
[ Public Traefik v3 Edge Proxy ]  (print.brain.cs.ait.ac.th)
               │  Automated Let's Encrypt SSL
               ▼
[ Web Print Service Container ]   (FastAPI on Proxmox VM / Cairo)
   • Google OAuth2 SSO (@ait.asia)
   • Identity Resolver (Email ──► CSIM Student ID via members.yaml)
   • PDF analysis, page range slicing, duplex injection
   • Pure-Python RFC 1179 LPD Spooler Engine
               │  Port 515 LPD
               ▼
[ CSIM Print Server: banyan.cs.ait.ac.th ]  (192.41.170.5:515)
   • Accounting Daemon verifies user quota for P<username>
   • Spools to physical printers
         ├──► Queue 'ricoh' / 'ricoh-colour'  ──► Ricoh IM C2000 (Lobby)
         └──► Queue 'magnum'                  ──► HP LaserJet P4015x (Room #212)
```

---

## 🖨️ Supported Printers & Queues

| Printer Hardware | Location | LPD Queue | Capabilities | CSIM Quota Cost |
| :--- | :--- | :--- | :--- | :--- |
| **Ricoh IM C2000** | CSIM Lobby Ground Floor | `ricoh` | Duplex, High Volume | **1×** (1 page per sheet side) |
| **Ricoh IM C2000** | CSIM Lobby Ground Floor | `ricoh-colour` | Duplex, Color | **10×** (10 pages per sheet side) |
| **HP LaserJet P4015x** | CSIM Room #212 | `magnum` | Duplex, 60 ppm, B&W | **1×** (1 page per sheet side) |

> [!CAUTION]
> **Color Printing Guardrail**: Color printing costs **10 times** standard quota. The web UI strictly defaults to Monochrome (B&W) and enforces an explicit acknowledgment checkbox before submitting color print jobs.

---

## 📁 Directory Structure
```
services/printing/
├── app/
│   ├── main.py              # FastAPI application entrypoint & REST endpoints
│   ├── auth.py              # Google OAuth2 SSO & members.yaml student ID resolver
│   ├── lpd.py               # Pure-Python RFC 1179 LPD client engine
│   ├── pdf_utils.py         # PDF page analyzer & PostScript duplex/color converter
│   ├── templates/
│   │   └── index.html       # Responsive Tailwind CSS drag-and-drop web UI
│   └── static/
│       └── app.js           # Client-side file drop, validation, and queue poller
├── Dockerfile               # Python 3.12-slim + poppler-utils + ghostscript
├── docker-compose.yml       # Production stack with Traefik labels & resource limits
├── requirements.txt         # FastAPI, Authlib, pypdf, pyyaml
├── .env.example             # Configuration and credentials template
└── README.md                # Service documentation (this file)
```

---

## 🚀 Deployment Instructions (Proxmox VM)

### 1. Prerequisites
- Target host has Docker Engine and Docker Compose installed.
- Host is enrolled in NetBird and belongs to group `brainlab-cluster` or `sysadmin` (ensuring access to `192.41.170.5` over `csim-infrastructure`).

### 2. Environment Configuration
Copy `.env.example` to `.env` and insert your credentials:
```bash
cp .env.example .env
```

Fill in:
- `GOOGLE_CLIENT_ID`: Retrieved from GCP Secret Manager (`google-oauth-client-id`).
- `GOOGLE_CLIENT_SECRET`: Retrieved from GCP Secret Manager (`google-oauth-client-secret`).
- `SESSION_SECRET_KEY`: Random 32-character string (`openssl rand -hex 16`).

### 3. Start Service
```bash
docker compose up -d --build
```

### 4. Health Check
```bash
curl -f http://localhost:8080/health
# {"status":"ok","service":"web-print"}
```
