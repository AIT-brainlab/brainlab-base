# Domain & DNS Architecture

## Overview
AIT Brainlab operates across institutional subdomains routed through GCP Cloud DNS and local reverse proxies.

---

## 1. Managed DNS Zones

### A. Public Authoritative Zones (`GCP Cloud DNS`)

| Domain / Record | Type | Target | Description |
| :--- | :---: | :--- | :--- |
| **`ldap.brain.cs.ait.ac.th`** | A | `34.87.117.183` (GCP VM) | LLDAP Web Admin & HTTPS Edge |
| **`netbird.brain.cs.ait.ac.th`** | A | `34.87.117.183` (GCP VM) | NetBird Dashboard, API & Signal (HTTPS/h2c) |
| **`la.cs.ait.ac.th`** | A | `192.41.170.39` (CSIM On-prem) | Production GPU JupyterHub Multi-User Platform |
| **`ml.brain.cs.ait.ac.th`** | A | `192.41.170.105` (CSIM On-prem) | MLflow & AI Demonstration Applications |
| **`*.ml.brain.cs.ait.ac.th`** | A | `192.41.170.105` (CSIM On-prem) | Subdomain routing for deployed machine learning APIs |

### B. Internal Mesh Resolution (`NetBird MagicDNS`)

Peers enrolled in the NetBird mesh resolve internal services directly via peer hostnames (zero split-horizon DNS overhead):

| Hostname / Service | Port / Protocol | Target Host | Description |
| :--- | :---: | :--- | :--- |
| **`ldap.brain.cs.ait.ac.th`** | `:443` (HTTPS) | `brainlab-mgmt-vm.netbird.selfhosted` (CNAME) | LLDAP Web Admin UI (Mesh-only with Let's Encrypt SSL) |
| **`brainlab-mgmt-vm`** | `:3890` (LDAP) | `brainlab-mgmt-vm` | Internal POSIX directory queries for Linux SSSD & TrueNAS |
| **`cairo`** | `:80` (HTTP) | `cairo` | TrueNAS SCALE Web Administration |
| **`la`** | `:2222` (SSH) | `la` | GPU compute node container SSH gateway |

---

## 2. Validation Commands
```bash
# Check resolution via Google Public DNS
dig @8.8.8.8 brain.cs.ait.ac.th +short

# Check Authoritative NS records
dig NS brain.cs.ait.ac.th +short
```
