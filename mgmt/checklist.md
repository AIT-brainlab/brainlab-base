# Master Implementation & Migration Task Checklist (`mgmt/`)

**Legend**: 🔴 Not Started | 🟡 In Progress | 🟢 Completed | 🔵 Verified

---

## 🎯 Architecture Review & Design Status: 🟢 COMPLETED
- [x] **Decoupled Billing & Compute**: Permanent management plane (`ait-brainlab-mgmt`) strictly separate from GPU workloads (`brainlab-res-*`).
- [x] **AuthN vs. AuthZ Decoupling**: Google OAuth2 handles 100% of user authentication & lifecycles; LLDAP acts as a passwordless authorization/POSIX directory.
- [x] **Multi-Email Binding**: Single POSIX UID supports `@ait.asia`, `@ait.ac.th`, and personal alumni `@gmail.com` with zero data copying on TrueNAS.
- [x] **Zero Internal TLS Overhead**: Internal LDAP runs over NetBird WireGuard encrypted mesh tunnel (`ldap://` on port `:3890`).
- [x] **Unified Control Plane VM**: Co-hosts LLDAP + Self-Hosted NetBird on a single lightweight VM (< 400 MB RAM).
- [x] **Terraform Production Suite**: Full IaC created in `mgmt/terraform/` with `prevent_destroy = true` shields for DNS & Secret Manager.

---

## 📋 Execution Roadmap (Pick Up Here When You Return!)

### Phase 1: GCP Management Plane Terraform Deployment
| Task ID | Task Description | Target Identity | Status | Notes / Output |
| :--- | :--- | :--- | :---: | :--- |
| `1.1` | Run `terraform init` and `terraform apply` in `mgmt/terraform/` | Akraradet | 🔴 **NEXT ACTION** | Provisions Cloud DNS, Secret Manager, IAM, and Alert channels |
| `1.2` | Copy Google Name Servers from `terraform output brainlab_zone_name_servers` | Akraradet | 🔴 | Prepare 4 NS records |
| `1.3` | Submit GCP NS record updates to parent domain registrar (`cs.ait.ac.th`) | Phue Pwint Thwe | 🔴 | Delegate NS authority to GCP |
| `1.4` | Configure GCS Remote Backend Bucket (`gs://ait-brainlab-mgmt-tfstate`) | Akraradet | 🔴 | Enable state locking and multi-admin collaboration |

---

### Phase 2: Terraform CI/CD & Governance Pipeline (GitHub Actions)
| Task ID | Task Description | Target Identity | Status | Notes / Output |
| :--- | :--- | :--- | :---: | :--- |
| `2.1` | Setup GCP Workload Identity Federation for GitHub Actions | Akraradet | 🔴 | Keyless secure auth for CI/CD |
| `2.2` | Create GitHub Actions workflow (`.github/workflows/terraform.yml`) | Akraradet | 🔴 | Auto-runs `terraform plan` on Pull Requests |
| `2.3` | Enable Branch Protection on `main` branch (Require 1 Admin Approval) | Akraradet | 🔴 | Prevents unauthorized `terraform apply` |
| `2.4` | Auto-apply Terraform changes upon merging approved PRs to `main` | Whole Team | 🔴 | Full GitOps audit trail |

---

### Phase 3: Unified Management VM Deployment (LLDAP + NetBird)
| Task ID | Task Description | Target Identity | Status | Notes / Output |
| :--- | :--- | :--- | :---: | :--- |
| `3.1` | Spin up lightweight Management VM (e2-small on GCP or on-prem VM) | Akraradet / Phue Pwint Thwe | 🔴 | < 400 MB RAM total |
| `3.2` | Deploy unified Docker Compose stack (`traefik` + `lldap` + `netbird`) | Phue Pwint Thwe | 🔴 | Base DN: `dc=brain,dc=cs,dc=ait,dc=ac,dc=th` |
| `3.3` | Verify automated Let's Encrypt SSL on `auth.brain.cs.ait.ac.th` & `vpn.brain.cs.ait.ac.th` | Phue Pwint Thwe | 🔴 | HTTPS operational |

---

### Phase 4: Identity & Directory Import
| Task ID | Task Description | Target Identity | Status | Notes / Output |
| :--- | :--- | :--- | :---: | :--- |
| `4.1` | Export existing user accounts, UIDs, and GIDs from on-premise OpenLDAP | Phue Pwint Thwe | 🔴 | Dump posixAccount attributes |
| `4.2` | Import user entries into `lldap` aligning UIDs/GIDs with TrueNAS (`cairo`) permissions | Phue Pwint Thwe | 🔴 | Preserves `/mnt/HDD/home` file owners |
| `4.3` | Update `/etc/sssd/sssd.conf` on compute nodes & NAS (`cairo`) to point to `lldap:3890` | Phue Pwint Thwe | 🔴 | Connect over NetBird WireGuard mesh |
| `4.4` | Test `getent passwd <user>` and verify NFS home directory read/write access | Phue Pwint Thwe | 🔴 | Test SSH & file access on `cairo` |

---

### Phase 5: NetBird Mesh Enrollment
| Task ID | Task Description | Target Identity | Status | Notes / Output |
| :--- | :--- | :--- | :---: | :--- |
| `5.1` | Fetch setup key from GCP Secret Manager: `gcloud secrets versions access latest --secret=netbird-onprem-setup-key` | Phue Pwint Thwe | 🔴 | Automatic enrollment token |
| `5.2` | Enroll on-prem servers (`la`, `tokyo`, `cairo`): `sudo netbird up --management-url https://vpn.brain.cs.ait.ac.th --key <KEY>` | Phue Pwint Thwe | 🔴 | Connect physical nodes |
| `5.3` | Verify peer-to-peer ping across mesh network | Whole Team | 🔴 | Direct WireGuard P2P |

---

### Phase 6: JupyterHub Google OIDC Integration
| Task ID | Task Description | Target Identity | Status | Notes / Output |
| :--- | :--- | :--- | :---: | :--- |
| `6.1` | Create OAuth2 Client ID & Secret in `GCP Console > APIs & Services` | Akraradet | 🔴 | Web application credential |
| `6.2` | Configure JupyterHub `oauthenticator.google` with email whitelist & LLDAP spawner hook | Akraradet | 🔴 | `@ait.asia`, `@ait.ac.th`, and approved `@gmail.com` |
| `6.3` | Test "Sign in with Google" flow for JupyterHub users | Whole Team | 🔴 | 1-click login + correct NFS mounts |
