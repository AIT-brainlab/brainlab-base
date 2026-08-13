# Infrastructure Implementation Plan & Tracking Checklist: AIT Brainlab

This document serves as the master implementation roadmap and task tracking checklist for deploying the **AIT Brainlab** cloud infrastructure (`ait-brainlab-mgmt`) and research grant pipeline.

---

## 1. Project Overview & Milestones

| Milestone | Target Objective | Estimated Cost | Lead Owner |
| :--- | :--- | :--- | :--- |
| **M1: Billing & Governance** | Upgrade expired Free Trial, set `brainlab@ait.asia` as Owner | ~$0.00 | Akraradet Sinsamersuk |
| **M2: Core DNS Protection** | Verify Cloud DNS for `brain.cs.ait.ac.th` & `dpi.ait.ac.th` | ~$0.45/month | Phue Pwint Thwe |
| **M3: NetBird Mesh VPN** | Setup NetBird Cloud & invite `@ait.asia`/`@gmail.com` members | $0.00/month | Akraradet Sinsamersuk |
| **M4: Central LDAP (`lldap`)**| Deploy `lldap` & configure SSSD on Linux & NAS (`cairo`) | ~$0.00 - $7.00/month | Phue Pwint Thwe |
| **M5: Web Auth (OIDC)** | Integrate Google OAuth2 into JupyterHub & web services | $0.00/month | Akraradet Sinsamersuk |
| **M6: Research Grants** | Apply for Google Cloud Research Credits & TRC TPUs | $0 out-of-pocket | Whole Team |

---

## 2. Master Task Tracking Checklist

Legend: 🔴 Not Started | 🟡 In Progress | 🟢 Completed | 🔵 Verified

### Phase 1: GCP Billing & Root Governance Setup
| Task ID | Task Description | Target Identity | Status | Notes / Output |
| :--- | :--- | :--- | :---: | :--- |
| `1.1` | Upgrade expired GCP Billing Account to Standard Billing in GCP Console | Akraradet | 🔴 | Requires credit/debit card verification |
| `1.2` | Assign `roles/owner` to `brainlab@ait.asia` across all projects | Akraradet | 🔴 | Guarantees non-expiring ownership |
| `1.3` | Confirm `ait-brainlab-mgmt` is linked to permanent active billing account | Akraradet | 🔴 | Protects Cloud DNS from downtime |

### Phase 2: Cloud DNS Verification & Delegation
| Task ID | Task Description | Target Identity | Status | Notes / Output |
| :--- | :--- | :--- | :---: | :--- |
| `2.1` | Verify Cloud DNS Managed Zone 1: `brain.cs.ait.ac.th` | Phue Pwint Thwe | 🔴 | Zone active in `ait-brainlab-mgmt` |
| `2.2` | Verify Cloud DNS Managed Zone 2: `dpi.ait.ac.th` | Phue Pwint Thwe | 🔴 | Zone active in `ait-brainlab-mgmt` |
| `2.3` | Test public DNS resolution via `dig brain.cs.ait.ac.th +short` | Phue Pwint Thwe | 🔴 | Verify NS record delegation |

### Phase 3: NetBird Zero-Trust Mesh VPN Deployment
| Task ID | Task Description | Target Identity | Status | Notes / Output |
| :--- | :--- | :--- | :---: | :--- |
| `3.1` | Create NetBird Cloud account at `app.netbird.io` via `brainlab@ait.asia` | Akraradet | 🔴 | Free Tier (up to 100 devices) |
| `3.2` | Configure Google OAuth2 SSO integration in NetBird dashboard | Akraradet | 🔴 | Enables 1-click Google login |
| `3.3` | Send NetBird invitations to lab members (`@ait.asia` & `@gmail.com`) | Akraradet | 🔴 | Invite members by email |
| `3.4` | Install NetBird agent on local compute nodes and NAS (`cairo`) | Phue Pwint Thwe | 🔴 | `netbird up --key <setup-key>` |
| `3.5` | Verify ping and WireGuard mesh connectivity across all nodes | Whole Team | 🔴 | Test ping across NetBird IPs |

### Phase 4: Central User Auth & LDAP Directory (`lldap`)
| Task ID | Task Description | Target Identity | Status | Notes / Output |
| :--- | :--- | :--- | :---: | :--- |
| `4.1` | Deploy `lldap` container (Cloud Run Serverless or `e2-micro` VM) | Phue Pwint Thwe | 🔴 | Config Base DN: `dc=brain,dc=cs,dc=ait,dc=ac,dc=th` |
| `4.2` | Create user entries in `lldap` mapping `@ait.asia`/`@gmail.com` to UIDs | Phue Pwint Thwe | 🔴 | Assign Unix usernames (e.g. `akraradet`) |
| `4.3` | Configure `sssd` / `pam_ldap` on local Linux compute nodes & NAS (`cairo`)| Phue Pwint Thwe | 🔴 | Point to LDAP port `:389` |
| `4.4` | Test `getent passwd` and NFS home directory permissions (`/home/user`) | Phue Pwint Thwe | 🔴 | Verify UID mapping on NAS |

### Phase 5: Web Services & JupyterHub Google OIDC Integration
| Task ID | Task Description | Target Identity | Status | Notes / Output |
| :--- | :--- | :--- | :---: | :--- |
| `5.1` | Create OAuth2 Client ID & Secret in `GCP Console > APIs & Services` | Akraradet | 🔴 | Web application credential |
| `5.2` | Configure JupyterHub `oauthenticator.google` with email whitelist | Akraradet | 🔴 | Allow `@ait.asia` + approved `@gmail.com` |
| `5.3` | Test "Sign in with Google" flow for JupyterHub users | Whole Team | 🔴 | Verify 1-click login |

### Phase 6: Google Cloud Research Grants & Credits Application
| Task ID | Task Description | Target Identity | Status | Notes / Output |
| :--- | :--- | :--- | :---: | :--- |
| `6.1` | Generate GCP cost estimate using GCP Pricing Calculator | Whole Team | 🔴 | Compute, storage, GPU budget |
| `6.2` | Submit Google Cloud Research Credits application ($5k Faculty / $1k PhD) | Whole Team | 🔴 | Submit at `edu.google.com/programs/research-credits/` |
| `6.3` | Submit TPU Research Cloud (TRC) application for free TPU access | Whole Team | 🔴 | Submit at `sites.research.google/trc/` |
| `6.4` | Redeem approved promo code in GCP Billing & link to research project | Akraradet | 🔴 | Link to `brainlab-res-*` project |
| `6.5` | Set budget alerts (50%, 80%, 90%, 100%) & Pub/Sub VM auto-shutdown | Akraradet | 🔴 | Safeguard against out-of-pocket charges |

---

## 3. Weekly Implementation Schedule

```
┌────────────────────────────────────────────────────────────────────────┐
│ WEEK 1: Billing, Governance & DNS Setup                                │
│ - Upgrade billing, assign `brainlab@ait.asia` owner, verify Cloud DNS. │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ WEEK 2: NetBird VPN & Web OIDC Setup                                   │
│ - Setup NetBird Cloud, invite members, configure JupyterHub Google SSO.│
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ WEEK 3: Central LDAP (`lldap`) & NAS Integration                       │
│ - Deploy `lldap`, map emails to UIDs, configure SSSD on Linux & NAS.  │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ WEEK 4: Research Credit Applications & Safeguards                      │
│ - Submit GCP Research Credit & TRC applications, set budget cappers.   │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Operational Contacts

| Role | Person / Group | Contact Information |
| :--- | :--- | :--- |
| **Lab Management Shared Group** | AIT Brainlab | `brainlab@ait.asia` |
| **Lead Admin & Billing Owner** | Akraradet Sinsamersuk | `089-122-2061` |
| **Co-Infrastructure Lead** | Phue Pwint Thwe | `062-638-0858` |
