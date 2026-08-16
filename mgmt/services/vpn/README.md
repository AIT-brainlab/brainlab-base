# Core VPN Service: NetBird WireGuard Mesh (`mgmt/services/vpn`)

## 1. Executive Overview

NetBird establishes a **zero-trust, peer-to-peer (P2P) WireGuard mesh network** connecting lab servers (`la`, `tokyo`, `cairo`), cloud GPU VMs, and remote student laptops into a single secure private subnet.

---

## 2. Key Architecture Principles

1. **Direct Peer-to-Peer (P2P) Data Plane**:
   - Traffic travels directly between peers using WireGuard encryption (ChaCha20-Poly1305).
   - Large dataset transfers (1TB+) between laptops and on-prem TrueNAS (`cairo`) travel over the local LAN / direct Internet tunnel, incurring **$0.00 in cloud bandwidth/egress fees**.
2. **Unified Control Plane VM**:
   - The NetBird Management & Signal service is co-hosted with LLDAP on the **Management VM** (`ait-brainlab-mgmt`).
   - Eliminates SaaS device limits and tier upgrade costs ($5/user/month) forever.
3. **Human OIDC vs. Headless Server Key Model**:
   - **Humans (Laptops/Macs)**: Authenticate 100% via **Google OAuth2 SSO** (`@ait.asia`). WireGuard keys are generated locally and automatically revoked upon graduation.
   - **Headless Servers (`la`, `tokyo`, `cairo`)**: Use the automated **Setup Key** stored in GCP Secret Manager.

---

## 3. Server Enrollment Workflow (`setup_node.sh`)

To connect a physical server or cloud VM to the NetBird mesh:

```bash
# 1. Fetch the setup key from GCP Secret Manager
SETUP_KEY=$(gcloud secrets versions access latest --secret="netbird-setup-key" --project="ait-brainlab-mgmt")

# 2. Run the enrollment script
chmod +x setup_node.sh
sudo ./setup_node.sh "$SETUP_KEY"
```

---

## 4. Useful Diagnostics Commands

```bash
# Check connection status & local NetBird IP
netbird status

# List connected mesh peers
netbird status --detail

# Test direct peer ping to TrueNAS storage
ping 100.64.0.x
```
