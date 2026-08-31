# GCP Architecture & Infrastructure: `infra/cloud`

Welcome to the **AIT Brainlab** Google Cloud Platform (GCP) and cloud migration hub.

---

## 1. Directory Structure

```
infra/cloud/
├── README.md                      # Hub overview (this file)
├── docs/                          # Architectural documentation & migration plans
│   ├── ait_brainlab_mgmt.md       # Management plane architecture & task checklist
│   ├── migration_plan.md          # Step-by-step zero-downtime migration plan
│   └── research_credits_guide.md  # Guide to obtaining free GCP & TPU research credits
│
├── terraform/                     # Infrastructure as Code (IaC)
│   ├── mgmt/                      # 'ait-brainlab-mgmt' (Cloud DNS, IAM, and project APIs)
│   └── workloads/                 # 'brainlab-res-*' (Spot GPU VMs, GCS, budget safeguards)
│
└── scripts/                       # Migration & validation automation scripts
    ├── export_onprem_ldap.sh      # Export posix accounts from on-prem OpenLDAP
    ├── verify_dns.sh              # Validate Cloud DNS propagation and NS delegation
    └── sssd.conf.template         # Standardized SSSD configuration for Linux nodes & NAS
```

---

## 2. Documentation Links

- [**Management Plane (`ait-brainlab-mgmt`)**](docs/ait_brainlab_mgmt.md): Governance, billing, and checklist.
- [**On-Premise to GCP Migration Plan**](docs/migration_plan.md): Step-by-step zero-downtime migration runbook.
- [**Google Cloud Research Credits Guide**](docs/research_credits_guide.md): Application walkthrough for $5,000/yr faculty and $1,000/yr PhD grants.
