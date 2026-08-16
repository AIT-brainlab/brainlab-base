# Core VPN Service: NetBird Mesh (`mgmt/services/vpn`)

## Overview
NetBird establishes zero-trust WireGuard mesh connectivity across on-premise compute nodes (`la`, `tokyo`, `cairo`), GCP cloud nodes, and remote researchers.

---

## 1. Control Plane & Auth
- **Portal**: [`app.netbird.io`](https://app.netbird.io) (Managed Cloud SaaS).
- **SSO**: Google OAuth2 (`@ait.asia` & `@gmail.com`).

---

## 2. Enrolling Nodes
Run the setup script with the lab setup key:
```bash
chmod +x setup_node.sh
sudo ./setup_node.sh <SETUP_KEY>
```
