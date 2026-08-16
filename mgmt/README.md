# Core Management Plane (`ait-brainlab-mgmt`)

## 1. Executive Summary & Philosophy

The **AIT Brainlab Core Management Plane** (`mgmt/`) is the permanent, decoupled, low-cost ($0.45 - $7.45/month) control plane for the laboratory.

### Core Architectural Invariants:
1. **Decoupled Billing & Compute**:
   - `ait-brainlab-mgmt` is permanent and funded via institutional accounts.
   - **Never** provision heavy GPU compute or transient research workloads inside `ait-brainlab-mgmt`.
   - Ephemeral research compute belongs in dedicated `brainlab-res-*` projects funded by faculty/PhD grants.
2. **Unified Control Plane VM**:
   - Co-hosts **LLDAP** (Identity / POSIX directory) and **Self-Hosted NetBird** (VPN Control Plane & Signal) on a single lightweight VM (< 400 MB RAM total).
   - Permanently eliminates NetBird device limits and tier upgrade fees ($5/user/month).
   - Single unified backup target (`./data`) protects both identity and network state.
3. **Stateless Infrastructure ("Cattle, Not Pets")**:
   - The Management VM is 100% disposable. If destroyed, running `terraform apply` recreates the infrastructure and restores the directory from Git in seconds.
   - Permanent user research datasets reside safely on physical **TrueNAS NFS storage (`cairo:/mnt/HDD/home`)**.
4. **Terraform Safety Shield**:
   - Critical Cloud DNS zones (`brain.cs.ait.ac.th`, `dpi.ait.ac.th`) and Secret Manager keys (`netbird-onprem-setup-key`, `lldap-jwt-secret`) are shielded with `lifecycle { prevent_destroy = true }`.

---

## 2. End-to-End System Architecture Diagram

```mermaid
flowchart TB
    subgraph GITOPS ["GitOps and CI/CD Governance"]
        Admin["Lab Admins"] -->|Pull Request| Repo["GitHub Repository<br/>brainlab-base"]
        Repo -->|Automated Plan| GHA["GitHub Actions CI/CD"]
        Admin -->|Review and Approve PR| GHA
        GHA -->|Terraform Apply| GCS["GCS State Backend<br/>gs://ait-brainlab-mgmt-tfstate"]
    end

    subgraph GCP_MGMT ["GCP Project: ait-brainlab-mgmt (Control Plane)"]
        GHA -->|Provisions Infrastructure| CloudDNS["Cloud DNS<br/>brain.cs.ait.ac.th<br/>dpi.ait.ac.th"]
        GHA -->|Generates Root Keys| Secrets["Secret Manager<br/>netbird-onprem-setup-key<br/>lldap-jwt-secret"]
        
        GoogleAuth["Google OAuth2 / OIDC<br/>ait.asia and approved gmail"]

        subgraph MGMT_VM ["Unified Management VM (e2-small / 400 MB RAM)"]
            Traefik["Traefik Edge Proxy<br/>Auto Let's Encrypt SSL"]
            LLDAP["LLDAP Service<br/>Passwordless POSIX Directory"]
            NetBirdCtrl["Self-Hosted NetBird Control<br/>Management and Signal Server"]
            
            Traefik -->|auth.brain.cs.ait.ac.th| LLDAP
            Traefik -->|vpn.brain.cs.ait.ac.th| NetBirdCtrl
        end
    end

    subgraph ONPREM ["AIT Campus Physical Infrastructure (CSIM Network)"]
        Cairo["TrueNAS NFS cairo<br/>/mnt/HDD/home NFS Export<br/>Standard LDAP Client"]
        LA["GPU Compute Node la<br/>JupyterHub + DockerSpawner<br/>Local NVIDIA GPUs"]
        Tokyo["Service Node tokyo<br/>MLflow Server :5000<br/>FastAPI Web Demos"]
        Desktop["Lab Ubuntu Desktop<br/>SSSD PAM Desktop Login<br/>CSIM Printer Terminal"]
    end

    subgraph CLIENTS ["Lab Members and Students"]
        StudentWeb["Web Browser<br/>JupyterHub / Demos"]
        StudentLaptop["Student Laptops<br/>NetBird Client App"]
    end

    %% Web Access Flow
    StudentWeb -->|1. Sign in with Google| GoogleAuth
    GoogleAuth -->|2. Return Verified Email| LA
    LA -->|3. Query POSIX UID and GID on port 3890| LLDAP
    LA -->|4. Mount User Home Directory| Cairo

    %% VPN Mesh Flow
    StudentLaptop -->|Google SSO Login| NetBirdCtrl
    StudentLaptop <-->|Direct P2P WireGuard Tunnel| LA
    StudentLaptop <-->|Direct P2P WireGuard Tunnel| Tokyo
    StudentLaptop <-->|Direct P2P WireGuard Tunnel| Cairo

    %% Internal LDAP Queries over Encrypted Tunnel
    Cairo -.->|Internal LDAP Query on port 3890| LLDAP
    Desktop -.->|SSSD PAM Auth Query on port 3890| LLDAP
    LA -.->|Container UID Spawner Query| LLDAP

    %% Headless Server Key Provisioning
    Secrets -.->|Auto-Enrollment Key on Boot| LA
    Secrets -.->|Auto-Enrollment Key on Boot| Tokyo
    Secrets -.->|Auto-Enrollment Key on Boot| Cairo
```

---

## 3. Multi-Account Root Governance

| Identity / Account | Role | Purpose | Billing Responsibility |
| :--- | :--- | :--- | :--- |
| `brainlab@ait.asia` | **Project Owner** | Primary institutional account | Long-term institutional asset ownership |
| `st121413@ait.asia` | **Project Owner** | Lead System Administrator | Day-to-day operations & Terraform deployments |
| `akraradets@gmail.com` | **Project Owner & Billing Admin** | Permanent personal backup | Primary billing account attached to `ait-brainlab-mgmt` |

---

## 4. Directory Layout (`mgmt/`)

```
mgmt/
├── README.md                  # This architecture runbook
├── checklist.md               # Master migration & implementation tracker
├── migration_plan.md          # Zero-downtime transition SOP
│
├── terraform/                 # Dedicated Terraform IaC suite
│   ├── main.tf                # GCP APIs & Provider configuration
│   ├── dns.tf                 # Cloud DNS zones (brain.cs.ait.ac.th, dpi.ait.ac.th)
│   ├── iam.tf                 # Root owners & automation service account
│   ├── secrets.tf             # Secret Manager (LLDAP & NetBird keys)
│   ├── budget.tf              # Budget monitoring & alert channels
│   ├── variables.tf           # Configurable inputs & IP addresses
│   ├── outputs.tf             # NS delegation records
│   └── README.md              # Terraform execution runbook
│
└── services/                  # Core Management Services
    ├── dns/                   # DNS verification & delegation scripts
    ├── identity/              # lldap configuration, schema, SSSD templates
    └── vpn/                   # NetBird node enrollment & routing scripts
```

---

## 5. Operational Cost Breakdown

| Component | Target Hosting | Expected Monthly Cost |
| :--- | :--- | :--- |
| **Cloud DNS** | GCP Cloud DNS (2 Managed Zones) | ~$0.45 / month |
| **Unified Control Plane VM** | GCP `e2-small` VM (or on-prem container) | ~$0.00 (On-Prem) to $7.00/mo (GCP) |
| **NetBird Mesh VPN** | Self-Hosted on Management VM | **$0.00 / month (Unlimited Devices)** |
| **Secret Manager** | GCP Secret Manager (3 active secrets) | ~$0.00 / month (Free tier) |
| **Total Management Plane Cost** | | **~$0.45 to $7.45 / month** |
