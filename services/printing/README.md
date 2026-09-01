# Remote Web Print Service (`services/printing`)

## 📌 Overview
The **AIT Brainlab Remote Web Print Service** ([https://print.brain.cs.ait.ac.th](https://print.brain.cs.ait.ac.th)) allows lab researchers, students, and alumni to upload and print PDF documents to CSIM physical laboratory printers from any device, anywhere (on or off campus).

It authenticates users using **Google OAuth2 SSO** (`@ait.asia`, `@ait.ac.th`, and approved lab alumni `@gmail.com`) and automatically submits print jobs to the CSIM print server (`banyan.cs.ait.ac.th:515`) using the RFC 1179 LPD protocol, attributing quota deduction directly to the student's CSIM account.

---

## 🏗️ Architecture & Stack

```
[ Researcher / Student Browser ]
               │  HTTPS (Port 443)
               ▼
[ Public Traefik v3 Edge Proxy ]  (print.brain.cs.ait.ac.th on VM 100)
   • Let's Encrypt Automated SSL/TLS
   • Security Headers (HSTS, Anti-Clickjacking, XSS, nosniff)
   • Rate Limiting: 100 req/min (Burst: 50)
   • Max Request Body Cap: 25 MB (DoS protection)
               │  HTTP (Port 80 via 10.10.250.120)
               ▼
[ Web Print Service Container ]   (FastAPI on brainlab-services VM 120)
   • Google OAuth2 SSO (@ait.asia & alumni @gmail.com)
   • CSIM Identity Resolver (Email ──► CSIM Student ID via members.yaml)
   • PDF page analysis, page range slicing, duplex injection
   • Pure-Python RFC 1179 LPD Spooler Engine
               │  Port 515 LPD (over WireGuard Mesh / CSIM LAN)
               ▼
[ CSIM Print Server: banyan.cs.ait.ac.th ]  (192.41.170.5:515)
   • Accounting Daemon verifies user quota for P<csim_account> (e.g. Pst121413)
   • Spools to physical printers
         ├──► Queue 'ricoh' / 'ricoh-colour'  ──► Ricoh IM C2000 (Lobby Ground Floor)
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

## 👤 Identity & CSIM Student Quota Binding

The print service resolves user accounts dynamically via [`mgmt/identity/members.yaml`](file:///Users/akraradets/Projects/AIT-brainlab/brainlab-base/mgmt/identity/members.yaml):
* **Active Students**: Accounts with `stXXXXXX@ait.asia` or `uid >= 100000` automatically map to their student ID `stXXXXXX`.
* **Alumni**: Graduated members signing in with personal `@gmail.com` have their student ID bound via `csim_account: stXXXXXX` in `members.yaml`.
* **Unlinked Accounts**: Users without a registered CSIM student account are prompted with a clear UI warning under **Quota Attribution** and print submissions are safely blocked (`HTTP 403`).

---

## 📁 Directory Structure
```text
services/printing/
├── app/
│   ├── main.py              # FastAPI application entrypoint & REST endpoints
│   ├── auth.py              # Google OAuth2 SSO & members.yaml CSIM student ID resolver
│   ├── lpd.py               # Pure-Python RFC 1179 LPD client engine
│   ├── pdf_utils.py         # PDF page analyzer, page range parser & pdftops PostScript converter
│   ├── templates/
│   │   └── index.html       # Responsive Tailwind CSS drag-and-drop web UI
│   └── static/
│       └── app.js           # Client-side file drop, validation, and queue poller
├── Dockerfile               # Python 3.12-slim + poppler-utils + ghostscript
├── docker-compose.yml       # Production stack on traefik-net
├── requirements.txt         # FastAPI, Authlib, pypdf, pyyaml
├── .env.example             # Configuration and credentials template
└── README.md                # Service documentation (this file)
```

---

## 🚀 Deployment Instructions (Proxmox VM 120)

### 1. Environment Configuration
Create `/projects/print/.env` on `brainlab-services`:
```bash
GOOGLE_CLIENT_ID="<from GCP Secret Manager: google-oauth-client-id>"
GOOGLE_CLIENT_SECRET="<from GCP Secret Manager: google-oauth-client-secret>"
SESSION_SECRET_KEY="<random 32-character string>"
```

### 2. Start Service
```bash
cd /projects/print
sudo docker compose up -d --build
```

### 3. Health Check
```bash
curl -f http://localhost:80/health
# {"status":"ok","service":"web-print","members_loaded":34}
```
