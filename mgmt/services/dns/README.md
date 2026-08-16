# Core DNS Service (`mgmt/services/dns`)

## Overview
Authoritative DNS resolution for `brain.cs.ait.ac.th` and `dpi.ait.ac.th` hosted on Google Cloud DNS within `ait-brainlab-mgmt`.

---

## 1. Managed Zones & Delegation
- **`brain.cs.ait.ac.th`**: NS records delegated from `cs.ait.ac.th`.
- **`dpi.ait.ac.th`**: NS records delegated from `ait.ac.th`.

---

## 2. Testing Propagation
Run the validation script:
```bash
chmod +x verify_dns.sh
./verify_dns.sh brain.cs.ait.ac.th
```
