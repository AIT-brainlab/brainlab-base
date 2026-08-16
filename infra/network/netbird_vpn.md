# NetBird WireGuard Mesh VPN Architecture

## Overview
NetBird establishes an encrypted, zero-trust peer-to-peer WireGuard network interconnecting physical lab servers, cloud compute instances on GCP, and remote researcher laptops.

---

## 1. Network Topology
- **Unified Control Plane**: Co-hosted on Management VM (`ait-brainlab-mgmt`) at `https://netbird.brain.cs.ait.ac.th`.
- **Authentication**: Single Sign-On via Google OAuth2 (`@ait.asia` & `@gmail.com`).
- **Data Plane**: Direct peer-to-peer (P2P) WireGuard UDP tunneling with automatic STUN/TURN NAT traversal (zero cloud bandwidth costs).

---

## 2. Onboarding a Headless Lab Server
Run the setup script with the lab enrollment key fetched from GCP Secret Manager:

```bash
# 1. Install NetBird client
sudo curl -fsSL https://pkgs.netbird.io/install.sh | sh

# 2. Fetch enrollment key from Secret Manager
SETUP_KEY=$(gcloud secrets versions access latest --secret="netbird-setup-key" --project="ait-brainlab-mgmt")

# 3. Connect to the mesh
sudo netbird up --management-url https://netbird.brain.cs.ait.ac.th --key "$SETUP_KEY"
```

---

## 3. Verifying Peer Status
```bash
# Check client connection state
netbird status

# Check peer list and latency
netbird status -d
```
