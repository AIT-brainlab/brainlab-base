# NetBird WireGuard Mesh VPN Architecture

## Overview
NetBird establishes an encrypted, zero-trust peer-to-peer WireGuard network interconnecting physical lab servers, cloud compute instances on GCP, and remote researcher laptops.

---

## 1. Network Topology
- **Managed Control Plane**: [`app.netbird.io`](https://app.netbird.io) (Managed Cloud SaaS).
- **Authentication**: Single Sign-On via Google OAuth2 (`@ait.asia` & `@gmail.com`).
- **Data Plane**: Direct peer-to-peer WireGuard UDP tunneling with automatic STUN/TURN NAT traversal.

---

## 2. Onboarding a New Lab Machine
Run the setup script with the lab enrollment key:
```bash
sudo curl -fsSL https://pkgs.netbird.io/install.sh | sh
sudo netbird up --management-url https://api.netbird.io --key <LAB_SETUP_KEY>
```

---

## 3. Verifying Peer Status
```bash
# Check client connection state
netbird status

# Check peer list and latency
netbird status -d
```
