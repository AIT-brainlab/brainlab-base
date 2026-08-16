# Infrastructure Domain (`infra/`)

The **Infrastructure Domain** contains all configurations, runbooks, and Infrastructure as Code (IaC) for physical servers, network routing, and cloud resources.

---

## 🏗️ Sub-Domains

| Directory | Scope | Key Technologies |
| :--- | :--- | :--- |
| [**`infra/onprem/`**](onprem/README.md) | Physical compute nodes, GPU drivers, NAS storage mounts | Ubuntu 22.04, NVIDIA CUDA, TrueNAS NFS, Docker |
| [**`infra/cloud/`**](cloud/README.md) | GCP Management Plane (`ait-brainlab-mgmt`) & Research VMs | Terraform, Cloud DNS, Spot GPUs, GCS |
| [**`infra/network/`**](network/README.md) | Mesh VPN, proxy rules, and DNS resolution | NetBird, CSIM Proxy `3128`, Cloud DNS |
