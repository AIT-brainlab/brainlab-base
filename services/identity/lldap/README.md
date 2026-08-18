# `lldap` User Directory Service (`services/identity/lldap`)

## Overview
`lldap` acts as the **100% Stateless GitOps Authorization Directory** for AIT Brainlab. It maps `@ait.asia` and `@gmail.com` identities to numeric Unix `posixAccount` UIDs/GIDs, home directory storage paths, and group memberships.

---

## 🏛️ Architecture & Control Plane
- **Live Endpoint**: `https://authen2.brain.cs.ait.ac.th` (Staging) / `https://authen.brain.cs.ait.ac.th` (Production)
- **Port `:3890`**: Internal LDAP query port accessible over NetBird WireGuard mesh.
- **Port `:443`**: Traefik-managed HTTPS Web Portal & GraphQL API.
- **GitOps Management**: Provisioned and managed entirely via Terraform in [`mgmt/terraform/identity/`](../../mgmt/terraform/identity/).

---

## 🚀 Managing Users & Groups
To add, modify, or remove users, edit [`mgmt/terraform/identity/users.tf`](../../mgmt/terraform/identity/users.tf) and run:

```bash
cd mgmt/terraform/identity
terraform apply
```

To test live credentials and directory resolution:
```bash
cd mgmt/terraform/identity
python3 test_login.py
```
