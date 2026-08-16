# Domain & DNS Architecture

## Overview
AIT Brainlab operates across institutional subdomains routed through GCP Cloud DNS and local reverse proxies.

---

## 1. Managed DNS Zones

| Domain Zone | Primary Host | Resolution | Description |
| :--- | :--- | :--- | :--- |
| **`brain.cs.ait.ac.th`** | GCP Cloud DNS | Public | Core Lab Services (JupyterHub, Auth) |
| **`dpi.ait.ac.th`** | GCP Cloud DNS | Public | DPI Center Partner Services |
| **`tokyo.cs.ait.ac.th`** | Local Traefik | Public | Research APIs and Demonstration Apps |
| **`la.cs.ait.ac.th`** | Local Node | Public | Primary On-Prem JupyterHub Endpoint |

---

## 2. Validation Commands
```bash
# Check resolution via Google Public DNS
dig @8.8.8.8 brain.cs.ait.ac.th +short

# Check Authoritative NS records
dig NS brain.cs.ait.ac.th +short
```
