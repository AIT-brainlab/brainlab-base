# Master Implementation & Migration Task Checklist (`mgmt/`)

Legend: 🔴 Not Started | 🟡 In Progress | 🟢 Completed | 🔵 Verified

---

## Phase 1: GCP Billing & Root Governance Setup
| Task ID | Task Description | Target Identity | Status | Notes / Output |
| :--- | :--- | :--- | :---: | :--- |
| `1.1` | Upgrade expired GCP Billing Account to Standard Billing in GCP Console | Akraradet (`akraradets@gmail.com`) | 🔵 | Requires credit/debit card verification |
| `1.2` | Confirm `roles/owner` is assigned to `brainlab@ait.asia`, `st121413@ait.asia`, and `akraradets@gmail.com` | Akraradet | 🔵 | Guarantees multi-account access safety |
| `1.3` | Confirm `ait-brainlab-mgmt` is linked to permanent active billing account | Akraradet | 🔵 | Protects Cloud DNS from downtime |

---

## Phase 2: DNS Migration (On-Premise DNS $\rightarrow$ GCP Cloud DNS)
| Task ID | Task Description | Target Identity | Status | Notes / Output |
| :--- | :--- | :--- | :---: | :--- |
| `2.1` | Export active DNS records (A, CNAME, TXT) from on-premise DNS server | Phue Pwint Thwe | 🔵 | Audit existing zone files |
| `2.2` | Replicate zone records in GCP Cloud DNS (`brain.cs.ait.ac.th` & `dpi.ait.ac.th`) | Phue Pwint Thwe | 🔵 | Managed zones in `ait-brainlab-mgmt` |
| `2.3` | Submit GCP NS record updates to parent domain registrar (`cs.ait.ac.th`) | Phue Pwint Thwe | 🔴 | Delegate NS authority to GCP |
| `2.4` | Test public DNS resolution via `dig brain.cs.ait.ac.th +short` & `dig @8.8.8.8` | Phue Pwint Thwe | 🔴 | Verify dual resolution |
| `2.5` | Decommission on-premise local DNS server after TTL expiration | Phue Pwint Thwe | 🔴 | Safe shutdown after 24-48 hrs |

---

## Phase 3: NetBird Migration (Self-Hosted On-Prem $\rightarrow$ NetBird Cloud)
| Task ID | Task Description | Target Identity | Status | Notes / Output |
| :--- | :--- | :--- | :---: | :--- |
| `3.1` | Create NetBird Cloud account at `app.netbird.io` via `brainlab@ait.asia` | Akraradet | 🔴 | Free Tier (up to 100 devices) |
| `3.2` | Configure Google OAuth2 SSO integration in NetBird dashboard | Akraradet | 🔴 | Enables 1-click Google login |
| `3.3` | Send NetBird invitations to lab members (`@ait.asia` & `@gmail.com`) | Akraradet | 🔴 | Invite members by email |
| `3.4` | Re-key local compute nodes and NAS (`cairo`): `netbird down && netbird up --key <new-key>` | Phue Pwint Thwe | 🔴 | Re-connect nodes to NetBird Cloud |
| `3.5` | Verify ping and WireGuard mesh connectivity across all nodes on `app.netbird.io` | Whole Team | 🔴 | Test ping across NetBird IPs |
| `3.6` | Decommission on-premise NetBird server containers | Phue Pwint Thwe | 🔴 | Stop & remove old NetBird containers |

---

## Phase 4: LDAP Migration (On-Prem LDAP $\rightarrow$ Cloud `lldap`)
| Task ID | Task Description | Target Identity | Status | Notes / Output |
| :--- | :--- | :--- | :---: | :--- |
| `4.1` | Export user accounts, UIDs, and GIDs from on-premise LDAP server | Phue Pwint Thwe | 🔴 | Dump posixAccount attributes |
| `4.2` | Deploy `lldap` container (Cloud Run Serverless or `e2-micro` VM) | Phue Pwint Thwe | 🔴 | Base DN: `dc=brain,dc=cs,dc=ait,dc=ac,dc=th` |
| `4.3` | Import user entries in `lldap` aligning UIDs/GIDs with NAS (`cairo`) permissions | Phue Pwint Thwe | 🔴 | Preserves `/mnt/HDD/home` file owners |
| `4.4` | Update `/etc/sssd/sssd.conf` on compute nodes & NAS (`cairo`) pointing to `lldap` `:389` | Phue Pwint Thwe | 🔴 | Point to Cloud Run/VM `lldap` IP |
| `4.5` | Test `getent passwd <user>` and verify NFS home directory read/write access | Phue Pwint Thwe | 🔴 | Test SSH & file access on `cairo` |
| `4.6` | Decommission on-premise OpenLDAP server (`sudo systemctl stop slapd`) | Phue Pwint Thwe | 🔴 | Shut down old LDAP service |

---

## Phase 5: Web Services & JupyterHub Google OIDC Integration
| Task ID | Task Description | Target Identity | Status | Notes / Output |
| :--- | :--- | :--- | :---: | :--- |
| `5.1` | Create OAuth2 Client ID & Secret in `GCP Console > APIs & Services` | Akraradet | 🔴 | Web application credential |
| `5.2` | Configure JupyterHub `oauthenticator.google` with email whitelist | Akraradet | 🔴 | Allow `@ait.asia` + approved `@gmail.com` |
| `5.3` | Test "Sign in with Google" flow for JupyterHub users | Whole Team | 🔴 | Verify 1-click login |

---

## Phase 6: Google Cloud Research Grants & Credits Application
| Task ID | Task Description | Target Identity | Status | Notes / Output |
| :--- | :--- | :--- | :---: | :--- |
| `6.1` | Generate GCP cost estimate using GCP Pricing Calculator | Whole Team | 🔴 | Compute, storage, GPU budget |
| `6.2` | Submit Google Cloud Research Credits application ($5k Faculty / $1k PhD) | Whole Team | 🔴 | Submit at `edu.google.com/programs/research-credits/` |
| `6.3` | Submit TPU Research Cloud (TRC) application for free TPU access | Whole Team | 🔴 | Submit at `sites.research.google/trc/` |
| `6.4` | Redeem approved promo code in GCP Billing & link to research project | Akraradet | 🔴 | Link to `brainlab-res-*` project |
| `6.5` | Set budget alerts (50%, 80%, 90%, 100%) & Pub/Sub VM auto-shutdown | Akraradet | 🔴 | Safeguard against out-of-pocket charges |
