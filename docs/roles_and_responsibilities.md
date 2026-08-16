# Roles, Responsibilities & Handover Matrix

## Overview
This document defines the handover expectations and operational responsibilities between the **Infrastructure Admin** and **Service Admin** for AIT Brainlab.

---

## 👥 Responsibility Matrix

| Operational Task | Primary Lead | Supporting Lead | Documentation Reference |
| :--- | :--- | :--- | :--- |
| **New Physical Server Provisioning** | Infrastructure Admin | Service Admin | [`infra/onprem/os_setup.md`](../infra/onprem/os_setup.md) |
| **NVIDIA Driver & CUDA Upgrades** | Infrastructure Admin | Service Admin | [`infra/onprem/nvidia_gpu.md`](../infra/onprem/nvidia_gpu.md) |
| **TrueNAS NFS Storage & Quotas** | Infrastructure Admin | Service Admin | [`infra/onprem/truenas_nfs.md`](../infra/onprem/truenas_nfs.md) |
| **GCP Terraform & Cloud DNS** | Infrastructure Admin | Service Admin | [`infra/cloud/terraform/`](../infra/cloud/terraform/) |
| **NetBird Mesh VPN Maintenance** | Infrastructure Admin | Service Admin | [`infra/network/netbird_vpn.md`](../infra/network/netbird_vpn.md) |
| **JupyterHub Spawner & Images** | Service Admin | Infrastructure Admin | [`services/jupyterhub/`](../services/jupyterhub/) |
| **User Onboarding & Identity** | Service Admin | Infrastructure Admin | [`docs/onboarding.md`](onboarding.md) |
| **MLflow Server & Artifacts** | Service Admin | Infrastructure Admin | [`services/mlflow/`](../services/mlflow/) |
| **Traefik Reverse Proxy & APIs** | Service Admin | Infrastructure Admin | [`services/api/`](../services/api/) |
| **Incident Triage & Debugging** | Shared | Shared | [`docs/troubleshooting.md`](troubleshooting.md) |
