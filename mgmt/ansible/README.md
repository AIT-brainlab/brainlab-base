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
Ensure `ansible-core` is available:
```bash
uv tool install ansible-core
```

### 1. Enroll the Management VM (GCP Cloud)
```bash
ansible-playbook -i inventory.ini enroll_netbird.yml --limit mgmt
```

### 2. Enroll TrueNAS Storage Node (`cairo`)
```bash
ansible-playbook -i inventory.ini enroll_netbird.yml --limit storage
```
*(Or specify the TrueNAS host/IP directly: `ansible-playbook -i "192.41.170.x," enroll_netbird.yml --limit storage`)*

### 3. Enroll Compute Nodes (`la`, `tokyo`)
```bash
ansible-playbook -i inventory.ini enroll_netbird.yml --limit servers
```

### 4. Enroll All Hosts Concurrently
```bash
ansible-playbook -i inventory.ini enroll_netbird.yml
```

---

## 📁 Directory Structure
```
mgmt/ansible/
├── ansible.cfg            # Global Ansible configuration & SSH pipelining
├── inventory.ini          # Hosts inventory (mgmt, storage, servers)
├── enroll_netbird.yml     # Automated NetBird peer enrollment playbook
└── README.md              # Operational runbook (this file)
```
