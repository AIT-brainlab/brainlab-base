# Modular Terraform Infrastructure: `ait-brainlab-mgmt`

To eliminate complexity, minimize risk, and achieve **100% Stateless GitOps**, the management plane infrastructure is divided into **6 independent, bite-sized modules** backed by a central **Google Cloud Storage (GCS) Remote State Backend** (`gs://ait-brainlab-mgmt-tfstate`).

---

## 🛠️ Phase 0: One-Time Foundation Prerequisites (Done Once Forever)

The following steps are performed **manually once** when setting up the GCP project. Future SysAdmins and CI/CD pipelines will **skip this step**:

1. **GCP Project**: `ait-brainlab-mgmt` created.
2. **GCP Billing**: Permanent billing account linked.
3. **GCS State Bucket**: Created with versioning enabled:
   ```bash
   gcloud storage buckets create gs://ait-brainlab-mgmt-tfstate \
     --project=ait-brainlab-mgmt \
     --location=asia-southeast1 \
     --uniform-bucket-level-access

   gcloud storage buckets update gs://ait-brainlab-mgmt-tfstate --versioning
   ```

---

## 🧭 The 6-Stage Modular Deployment Sequence

```mermaid
flowchart LR
    Seq1["👥 1. IAM<br/>🔵 Live"] --> Seq2["🌐 2. DNS<br/>🔵 Live"] --> Seq3["🔐 3. Secrets<br/>🔵 Live"] --> Seq4["🖥️ 4. VM Engine<br/>🔵 Live"] --> Seq5["👤 5. Identity<br/>🔵 Live"] --> Seq6["📡 6. VPN<br/>(NetBird ACLs)"]
```

| Sequence | Module | Purpose | GCS Prefix | Status | Guide |
| :---: | :--- | :--- | :---: | :---: | :--- |
| **1** | [**`iam/`**](iam/README.md) | **Governance First**: Root Project Owners (`brainlab`, `st121413`, `akraradets`) & `brainlab-mgmt-terraform` service account. | `iam` | 🔵 **VERIFIED** | [`iam/README.md`](iam/README.md) |
| **2** | [**`dns/`**](dns/README.md) | **Network & Routing**: Authoritative Cloud DNS zones (`brain.cs.ait.ac.th`, `dpi.ait.ac.th`) & all 14 service records. | `dns` | 🔵 **VERIFIED** | [`dns/README.md`](dns/README.md) |
| **3** | [**`secrets/`**](secrets/README.md) | **Credentials & Keys**: Secret Manager storage for `lldap-jwt`, `lldap-admin-password`, and `netbird-setup-key`. | `secrets` | 🔵 **VERIFIED** | [`secrets/README.md`](secrets/README.md) |
| **4** | [**`vm/`**](vm/README.md) | **Disposable Compute Engine**: `e2-micro` VM with Static IP running Traefik, LLDAP, and NetBird via Docker Compose. | `vm` | 🔵 **VERIFIED** | [`vm/README.md`](vm/README.md) |
| **5** | [**`identity/`**](identity/README.md) | **Identity-as-Code**: Declarative LLDAP users, Unix numeric UIDs/GIDs, and Multi-Email Bindings. | `identity` | 🔵 **VERIFIED** | [`identity/README.md`](identity/README.md) |
| **6** | [**`vpn/`**](vpn/README.md) | **NetBird-as-Code**: Declarative device groups, server setup keys, and Zero-Trust ACL policies. | `vpn` | 🔴 **NEXT** | [`vpn/README.md`](vpn/README.md) |

---

## 🛡️ Why This Architecture is 100% Stateless & Self-Healing

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│               AIT BRAINLAB 100% STATELESS GITOPS ARCHITECTURE                          │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ 1. 👤 Identity & UIDs       ──► Stored in Git (`identity/*.tf`). No passwords in LLDAP.│
│ 2. 📡 VPN Groups & ACLs     ──► Stored in Git (`vpn/*.tf`). Rebuilds in 5 seconds.     │
│ 3. 🌐 Domain Resolution     ──► Stored in Git (`dns/*.tf`) & Google Anycast DNS.       │
│ 4. 👥 Access Governance     ──► Stored in Git (`iam/*.tf`) & GCP IAM.                  │
│ 5. 🔐 Secrets & Tokens      ──► Stored in Secret Manager (`secrets/*.tf`).             │
│ 6. 🔒 SSL Certificates      ──► Self-healing: Traefik auto-renews Let's Encrypt SSL.   │
│ 7. 🖥️ VM Compute Engine     ──► 100% Disposable Cattle (`e2-micro`). Zero state stored. │
│ 8. 💾 Research Data         ──► Preserved on physical TrueNAS NFS (`/mnt/HDD/home`).   │
└────────────────────────────────────────────────────────────────────────────────────────┘
```
