# Core Management Plane (`ait-brainlab-mgmt`)

## 💡 The 30-Second Summary

`ait-brainlab-mgmt` is the **permanent Control Tower** for AIT Brainlab. It costs **<$5/month**, runs zero heavy compute, and is **100% Stateless & Self-Healing**.

It handles **3 essential jobs**:
1. **🌐 Domain Routing (Cloud DNS)**: Directs `*.brain.cs.ait.ac.th` to our physical and cloud services.
2. **👤 Identity & Access (LLDAP)**: Maps Google logins (`@ait.asia`) to Linux file permissions (`UID 1042`) without storing passwords.
3. **📡 Secure Mesh VPN (NetBird)**: Connects student laptops directly to on-prem GPU servers and TrueNAS storage from anywhere.

---

## 🏗️ Master Control Plane & Network Architecture

```mermaid
flowchart TD
    %% External Ingress
    Internet["🌐 Public Internet Users & Scanners"]
    Admins["👨‍💻 Project Admins<br/>(Google IAM Authenticated)"]
    OnPrem["🏢 Physical Lab Nodes (la, tokyo, cairo)<br/>(CSIM Server Room & NAS)"]

    subgraph GCP_FIREWALL ["🛡️ Google Cloud VPC Firewall (Datacenter Edge)"]
        FW_Web["ALLOW: Port 80 (HTTP) & Port 443 (HTTPS)"]
        FW_NB["ALLOW: Port 33073 (NetBird Signal UDP/TCP)"]
        FW_IAP["ALLOW: Port 22 (SSH strictly from Google IAP 35.235.240.0/20)"]
        FW_Block["🚫 BLOCKED FROM PUBLIC:<br/>Port 3890 (LDAP) & Port 22 (Direct SSH)"]
    end

    Internet -->|"HTTP / HTTPS"| FW_Web
    Internet -->|"WireGuard Signal"| FW_NB
    Internet -.->|"Direct SSH Scan / LDAP Scan"| FW_Block
    Admins -->|"gcloud compute ssh --tunnel-through-iap"| FW_IAP

    subgraph VM ["🖥️ Management VM Engine (brainlab-mgmt-vm)"]
        Traefik["🔒 Traefik v3 Proxy<br/>(:80, :443)<br/>• Auto Let's Encrypt SSL<br/>• Routes authen2 & netbird2"]
        NBSignal["📡 NetBird Signal<br/>(:33073 UDP/TCP)<br/>• Connection Broker"]
        
        subgraph PRIVATE_DOCKER ["📦 Private Docker Network (brainlab-mgmt-net)"]
            LLDAP["👤 LLDAP Engine<br/>• HTTP :17170 (Web Portal)<br/>• LDAP :3890 (User Queries)"]
            NBMgmt["📡 NetBird Management<br/>• API :33071 (Control Plane)"]
        end

        Traefik -->|"Proxy authen2.brain..."| LLDAP
        Traefik -->|"Proxy netbird2.brain..."| NBMgmt
    end

    FW_Web --> Traefik
    FW_NB --> NBSignal
    FW_IAP -->|"Encrypted IAP SSH Tunnel"| VM

    subgraph WIREGUARD_MESH ["🔒 NetBird Encrypted WireGuard Mesh Tunnel"]
        MeshFlow["Direct P2P Encrypted Mesh (100.64.0.x)"]
    end

    OnPrem <-->|"WireGuard Mesh Tunnel"| MeshFlow
    MeshFlow <-->|"Zero-Trust POSIX LDAP Queries (Port 3890)"| LLDAP
```

---

## 🛡️ The 100% Stateless GitOps Matrix

Every single element of the management plane is either **declared in Git** or **self-healing**, eliminating the need for fragile server backups:

| Component | Technology | Where State Lives | Self-Healing / Recovery |
| :--- | :--- | :--- | :--- |
| **👤 User Directory** | LLDAP | Git (`identity/*.tf`) | Terraform re-populates all UIDs & emails on boot in 3s. No passwords stored. |
| **📡 VPN Network** | NetBird | Git (`vpn/*.tf`) | Device groups & ACLs in code. Servers use Secret Manager key; humans use Google. |
| **🌐 Domain Routing** | Cloud DNS | Git (`dns/*.tf`) | 100% managed on Google Anycast network. Zero downtime during VM reboots. |
| **👥 Governance** | IAM | Git (`iam/*.tf`) | Root owners & automation service account versioned in Git. |
| **🔐 Credentials** | Secret Manager | GCP Secret Manager | Protected by `lifecycle.prevent_destroy = true`. |
| **🔒 SSL Certificates** | Traefik | Let's Encrypt ACME | Traefik automatically requests & renews HTTPS certs on boot in 10s. |
| **🖥️ Compute VM** | `e2-micro` | Disposable | 100% Cattle. If destroyed, rebuilt from Git in 45s. |
| **💾 User Data** | TrueNAS NFS | CSIM Server Room | All permanent research files stay safely on physical NAS (`/mnt/HDD/home`). |

---

## 👥 Root Governance & Ownership

| Account | Role | Responsibility |
| :--- | :--- | :--- |
| `brainlab@ait.asia` | **Project Owner** | Institutional lab asset ownership |
| `st121413@ait.asia` | **Project Owner** | Lead System Administrator |
| `akraradets@gmail.com` | **Project Owner & Billing** | Permanent personal billing anchor |

---

## 📁 Repository Layout

* [`checklist.md`](checklist.md): Master 8-phase implementation checklist with live verification statuses.
* [`migration_plan.md`](migration_plan.md): Zero-downtime on-prem to cloud migration and cutover SOP.
* [`terraform/`](terraform/): Modular Terraform IaC (`iam/`, `dns/`, `secrets/`, `vm/`, `identity/`, `vpn/`) backed by GCS remote state (`gs://ait-brainlab-mgmt-tfstate`).
* [`terraform/vm/`](terraform/vm/): Management VM, Traefik v3.7, LLDAP, NetBird v0.77.0, and monitoring scripts.
* [`terraform/identity/`](terraform/identity/): Identity-as-Code directory & multi-email bindings.
* [`terraform/vpn/`](terraform/vpn/): NetBird-as-Code zero-trust ACLs & server setup keys.
