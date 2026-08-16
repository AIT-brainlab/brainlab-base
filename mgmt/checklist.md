# Master Implementation & Migration Task Checklist (`mgmt/`)

**Legend**: 🔴 Not Started | 🟡 In Progress | 🟢 Completed | 🔵 Verified

---

## 🎯 Architecture Review & Design Status: 🟢 COMPLETED
- [x] **Decoupled Billing & Compute**: Permanent management plane (`ait-brainlab-mgmt`) strictly separate from GPU workloads (`brainlab-res-*`).
- [x] **AuthN vs. AuthZ Decoupling**: Google OAuth2 handles 100% of user authentication & lifecycles; LLDAP acts as a passwordless authorization/POSIX directory.
- [x] **Multi-Email Binding**: Single POSIX UID supports `@ait.asia`, `@ait.ac.th`, and personal alumni `@gmail.com` with zero data copying on TrueNAS.
- [x] **Zero Internal TLS Overhead**: Internal LDAP runs over NetBird WireGuard encrypted mesh tunnel (`ldap://` on port `:3890`).
- [x] **100% Stateless GitOps Control Plane**: All users, UIDs, VPN ACLs, and routing rules declared in Git; zero state stored on the VM.
- [x] **Canary Staging Strategy**: `authen2` & `netbird2` allow side-by-side testing with zero disruption to live on-prem services.

---

## 📋 Modular Execution Sequence

```mermaid
flowchart LR
    Step1["👥 1. IAM<br/>(terraform/iam/)<br/>🟢 COMPLETED"] --> Step2["🌐 2. DNS<br/>(terraform/dns/)<br/>🟢 COMPLETED"] --> Step3["🔐 3. Secrets<br/>(terraform/secrets/)<br/>🟢 COMPLETED"] --> Step4["🖥️ 4. VM Engine<br/>(terraform/vm/)<br/>🔴 CURRENT STEP"] --> Step5["👤 5. Identity-as-Code<br/>(terraform/identity/)"] --> Step6["📡 6. NetBird-as-Code<br/>(terraform/vpn/)"] --> Step7["🚀 7. OIDC Integration"] --> Step8["✂️ 8. Cutover & Decommission<br/>(Update DNS in Terraform)"]
```

---

### 👥 Phase 1: IAM & Project Governance (`mgmt/terraform/iam`)
| Task ID | Task Description | Target Identity | Status | Notes / Output |
| :--- | :--- | :--- | :---: | :--- |
| `1.1` | Run `terraform init` with GCS remote backend in `mgmt/terraform/iam/` | Akraradet | 🔵 | State locked in `gs://ait-brainlab-mgmt-tfstate/iam` |
| `1.2` | Apply `roles/owner` bindings for root project owners | Akraradet | 🔵 | `brainlab@ait.asia`, `st121413@ait.asia`, `akraradets@gmail.com` |
| `1.3` | Provision `brainlab-mgmt-terraform` service account with `roles/dns.admin` | Akraradet | 🔵 | Automation SA ready for CI/CD |

---

### 🌐 Phase 2: Cloud DNS Deployment (`mgmt/terraform/dns`)
| Task ID | Task Description | Target Identity | Status | Notes / Output |
| :--- | :--- | :--- | :---: | :--- |
| `2.1` | Run `terraform init` with GCS remote backend in `mgmt/terraform/dns/` | Akraradet | 🔵 | State locked in `gs://ait-brainlab-mgmt-tfstate/dns` |
| `2.2` | Adopt live GCP zones (`ait-brainlab`, `dpi-center`) and all 14 service records | Akraradet | 🔵 | 100% matched with zero drift |
| `2.3` | Apply Cloud DNS configuration with `lifecycle.prevent_destroy = true` | Akraradet | 🔵 | Nameservers permanently protected |
| `2.4` | Automated delegation health check via `bash check_delegation.sh` | Phue Pwint Thwe | 🔵 | `brain.cs.ait.ac.th` & `dpi.ait.ac.th` verified live! |

---

### 🔐 Phase 3: Secret Manager Deployment (`mgmt/terraform/secrets`)
| Task ID | Task Description | Target Identity | Status | Notes / Output |
| :--- | :--- | :--- | :---: | :--- |
| `3.1` | Run `terraform init` and `terraform apply` in `mgmt/terraform/secrets/` | Akraradet | 🔵 | Generated `lldap-jwt`, `lldap-admin-password`, `netbird-setup-key` |
| `3.2` | Automated zero-leakage secret verification via `bash check_secrets.sh` | Akraradet | 🔵 | All secrets verified live in Secret Manager |

---

### 🖥️ Phase 4: Disposable Management VM Engine (`mgmt/terraform/vm`)
| Task ID | Task Description | Target Identity | Status | Notes / Output |
| :--- | :--- | :--- | :---: | :--- |
| `4.1` | Run `terraform init` with GCS remote backend in `mgmt/terraform/vm/` | Akraradet | 🔵 | State locked in `gs://.../vm` |
| `4.2` | 1-Click Deploy: Launch `e2-micro` VM, Static IP, Firewall, and auto-paired DNS records (`authen2`, `netbird2`) | Akraradet | 🔵 | Docker stack + automated DNS |
| `4.3` | Automated staging health check via `bash check_vm_health.sh` | Akraradet | 🔵 | `authen2` (HTTP 200) & `netbird2` verified live! |

---

### 👤 Phase 5: Identity-as-Code Directory (`mgmt/terraform/identity`)
| Task ID | Task Description | Target Identity | Status | Notes / Output |
| :--- | :--- | :--- | :---: | :--- |
| `5.1` | Export existing user accounts, UIDs, and GIDs from on-premise OpenLDAP | Phue Pwint Thwe | 🔴 **CURRENT STEP** | Dump posixAccount attributes |
| `5.2` | Declare users, numeric UIDs, and email bindings in `users.tf` | Akraradet / Phue Pwint Thwe | 🔴 | Single source of truth in Git |
| `5.3` | Apply `bpg/lldap` Terraform module to seed LLDAP directory | Akraradet | 🔴 | Automated 3-second re-hydration |

---

### 📡 Phase 6: NetBird-as-Code Mesh Network (`mgmt/terraform/vpn`)
| Task ID | Task Description | Target Identity | Status | Notes / Output |
| :--- | :--- | :--- | :---: | :--- |
| `6.1` | Declare device groups (`servers`, `students`, `admins`) and Zero-Trust ACLs in `network.tf` | Akraradet | 🔴 | Versioned in Git |
| `6.2` | Enroll test nodes into the new mesh network using Secret Manager key | Phue Pwint Thwe | 🔴 | Connect test machines to `netbird2` |
| `6.3` | Verify peer-to-peer ping across new mesh network | Whole Team | 🔴 | Direct WireGuard P2P |

---

### 🚀 Phase 7: JupyterHub Google OIDC Integration
| Task ID | Task Description | Target Identity | Status | Notes / Output |
| :--- | :--- | :--- | :---: | :--- |
| `7.1` | Create OAuth2 Client ID & Secret in `GCP Console > APIs & Services` | Akraradet | 🔴 | Web application credential |
| `7.2` | Configure JupyterHub `oauthenticator.google` with email whitelist & LLDAP spawner hook | Akraradet | 🔴 | Test login with `@ait.asia` & `@gmail.com` |
| `7.3` | Verify end-to-end user home directory read/write on `/mnt/HDD/home` | Whole Team | 🔴 | Zero permission conflicts |

---

### ✂️ Phase 8: Production Cutover & On-Prem Decommissioning (DNS Cutoff)
| Task ID | Task Description | Target Identity | Status | Notes / Output |
| :--- | :--- | :--- | :---: | :--- |
| `8.1` | **Update DNS A Records in Terraform**: Update `authen` and `netbird` in `mgmt/terraform/dns/brainlab.tf` to Cloud VM Static IP | Akraradet | 🔴 | Apply `terraform apply` in `dns/` |
| `8.2` | **Enable Production Domain SSL in Traefik**: Add `authen` and `netbird` to `docker-compose.yml.tftpl` router rules so Let's Encrypt acquires production SSL | Akraradet | 🔴 | Automated production SSL issuance in <10s |
| `8.3` | **Re-point SSSD on Physical Nodes**: Update `/etc/sssd/sssd.conf` on compute nodes (`la`, `tokyo`) and NAS (`cairo`) to point to new LLDAP | Phue Pwint Thwe | 🔴 | Connect over NetBird WireGuard mesh |
| `8.4` | **Enroll Production On-Prem Servers**: Run `sudo netbird up` on `la`, `tokyo`, `cairo` with the new setup key | Phue Pwint Thwe | 🔴 | Switch all physical nodes to new mesh |
| `8.5` | **Decommission Legacy On-Prem Services**: Stop and disable old OpenLDAP (`slapd`) and legacy NetBird containers on `192.41.170.39` | Phue Pwint Thwe | 🔴 | Safe shutdown with zero rollback risk |
