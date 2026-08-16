# NetBird Managed Mesh VPN

## Overview
NetBird provides zero-trust, peer-to-peer WireGuard networking connecting on-premise compute nodes (e.g. `la`, `tokyo`, `cairo`) with GCP cloud instances and remote researchers.

## Architecture
- **Control Plane**: NetBird Managed Cloud ([`app.netbird.io`](https://app.netbird.io)) (Free Tier up to 100 devices).
- **Authentication**: Google OAuth2 SSO (`@ait.asia` & `@gmail.com`).

## Connecting a Node
```bash
sudo chmod +x setup_node.sh
sudo ./setup_node.sh <SETUP_KEY>
```
