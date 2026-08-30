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

### B. Internal Split-Horizon Mesh Zone (`NetBird WireGuard DNS`)

Peers enrolled in the NetBird mesh resolve internal services directly to their encrypted WireGuard overlay IPs:

| Internal FQDN | Record Type | NetBird Overlay IP | Target Host |
| :--- | :---: | :--- | :--- |
| **`ldap.brain.cs.ait.ac.th`** | A | `100.74.72.168` | `brainlab-mgmt-vm` (Port 3890 POSIX LDAP queries) |
| **`truenas.brain.cs.ait.ac.th`** | A | `100.74.68.117` | `cairo` (TrueNAS Web Administration) |
| **`cairo.brain.cs.ait.ac.th`** | A | `100.74.68.117` | `cairo` (Storage Node) |

---

## 2. Validation Commands
```bash
# Check resolution via Google Public DNS
dig @8.8.8.8 brain.cs.ait.ac.th +short

# Check Authoritative NS records
dig NS brain.cs.ait.ac.th +short
```
