# AIT Brainlab - Mesh Operations Ansible Playbooks (`mgmt/ansible`)

## 📌 Overview
This directory contains the automated **Day 1 Configuration Management & Peer Enrollment** playbooks for all physical GPU servers (`la`, `tokyo`), TrueNAS storage nodes (`cairo`), and the Cloud Management Control Plane (`brainlab-mgmt-vm`).

---

## 🏗 Architecture & Security Standards
1. **Dynamic Ephemeral Setup Keys**: Setup keys are **never hardcoded** in playbooks or inventory files. The playbook queries the live NetBird Management API via GCP Secret Manager (`netbird-mgmt-token`) at runtime.
2. **Composable Tag Enrollment**:
   - `mgmt`: Enrolls into `tier-mgmt`.
   - `storage` (`cairo`): Enrolls into `loc-onprem-csim` and `tier-storage`.
   - `servers` (`la`, `tokyo`): Enrolls into `loc-onprem-csim` and `tier-servers`.
3. **Idempotent Execution**: Running the playbook multiple times safely checks existing connections and reports current mesh status without disruption.

---

## 🚀 Running the Playbooks

### Prerequisites
`ansible-core` is already managed as a project dependency in the repository virtual environment:

```bash
# From the repository root, sync and activate the virtual environment:
uv sync
source .venv/bin/activate
```
*(Or invoke directly with `uv run ansible-playbook ...` without activating)*

### 1. Enroll the Management VM (GCP Cloud)
```bash
ansible-playbook -i inventory.ini enroll_netbird.yml --limit gcp-mgmt
```

### 2. Enroll TrueNAS Storage Node (`cairo`)
```bash
ansible-playbook -i inventory.ini enroll_netbird.yml --limit onprem-truenas
```
*(Or specify the TrueNAS host/IP directly: `ansible-playbook -i "192.41.170.x," enroll_netbird.yml --limit onprem-truenas`)*

### 3. Enroll Ubuntu Compute Nodes (`la`, `tokyo`)
```bash
ansible-playbook -i inventory.ini enroll_netbird.yml --limit onprem-ubuntu-server
```

### 4. Enroll All Hosts Concurrently
```bash
ansible-playbook -i inventory.ini enroll_netbird.yml
```

---

## 📁 Modular Directory Structure
```
mgmt/ansible/
├── ansible.cfg                # Global Ansible configuration & SSH pipelining
├── inventory.ini              # Clean hosts list (no inline commands)
├── enroll_netbird.yml         # Universal 30-line peer enrollment playbook
├── README.md                  # Operational runbook (this file)
│
├── group_vars/                # Tier-specific variables
│   ├── all.yml                # Global settings (NetBird URL, Python interpreter)
│   ├── gcp-mgmt.yml           # Container mode & mgmt-vm-enrollment key
│   ├── onprem-truenas.yml     # Package mode & truenas-storage-enrollment key
│   └── onprem-ubuntu-server.yml # Package mode & onprem-csim-enrollment key
│
├── host_vars/                 # Host-specific connection overrides
│   └── brainlab-mgmt-vm.yml   # GCP IAP Zero-Trust Tunnel & dynamic user resolution
│
└── roles/
    └── netbird-client/tasks/
        └── main.yml           # Unified role tasks (container & native package)
```
