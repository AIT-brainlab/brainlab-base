# Core DNS Service: Google Cloud DNS (`mgmt/services/dns`)

## 1. Overview

This service manages authoritative public DNS resolution for **AIT Brainlab** (`brain.cs.ait.ac.th`) and the partner **DPI Center** (`dpi.ait.ac.th`) hosted on Google Cloud DNS in `ait-brainlab-mgmt`.

---

## 2. Managed Zones & Delegation Hierarchy

```
                    [ AIT Root Registrar (ait.ac.th) ]
                                    │
         ┌──────────────────────────┴──────────────────────────┐
         ▼                                                     ▼
[ CSIM Subdomain (cs.ait.ac.th) ]                    [ DPI Center (dpi.ait.ac.th) ]
         │                                                     │
         │ NS Delegation                                       │ NS Delegation
         ▼                                                     ▼
┌───────────────────────────────┐                    ┌───────────────────────────────┐
│ Zone: `ait-brainlab`          │                    │ Zone: `dpi-center`            │
│ Domain: `brain.cs.ait.ac.th`  │                    │ Domain: `dpi.ait.ac.th`       │
└───────────────────────────────┘                    └───────────────────────────────┘
```

---

## 3. Active Service Record Map (`brain.cs.ait.ac.th`)

| Subdomain | Type | Target IP | Description |
| :--- | :---: | :--- | :--- |
| `authen.brain.cs.ait.ac.th` | A | `192.41.170.39` | LLDAP Identity Portal |
| `jupyterhub.brain.cs.ait.ac.th`| A | `192.41.170.39` | Multi-User JupyterHub GPU Notebooks |
| `netbird.brain.cs.ait.ac.th` | A | `192.41.170.39` | NetBird Mesh VPN Dashboard & Signal |
| `traefik.brain.cs.ait.ac.th` | A | `192.41.170.39` | Traefik Reverse Proxy Dashboard |
| `openwebui.brain.cs.ait.ac.th` | A | `192.41.170.39` | Open WebUI LLM Interface |
| `litellm.brain.cs.ait.ac.th` | A | `192.41.170.39` | LiteLLM Proxy Gateway |
| `nexterm.brain.cs.ait.ac.th` | A | `192.41.170.39` | Nexterm Web Terminal |
| `ml.brain.cs.ait.ac.th` | A | `192.41.170.105`| ML & Experimentation Services |
| `mlflow.ml.brain.cs.ait.ac.th`| A | `192.41.170.105`| MLflow Experiment Tracking Server |
| `aitgpt.dev.brain.cs.ait.ac.th`| A | `192.41.170.17` | AITGPT Development App |

---

## 4. Verification & Testing

To test whether DNS propagation is active and resolving to Google Cloud DNS:

```bash
# 1. Test via Google Public DNS (8.8.8.8)
dig @8.8.8.8 jupyterhub.brain.cs.ait.ac.th +short

# 2. Run automated validation script
chmod +x verify_dns.sh
./verify_dns.sh brain.cs.ait.ac.th
```

---

## 5. Terraform Automation

To modify or add new DNS records, use the modular Terraform configuration in [`mgmt/terraform/dns/`](../../terraform/dns/).
