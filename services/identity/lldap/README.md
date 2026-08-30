# `lldap` User Directory Service (`services/identity/lldap`)

## Overview
`lldap` acts as the **100% Stateless GitOps Authorization Directory** for AIT Brainlab. It maps `@ait.asia` and `@gmail.com` identities to numeric Unix `posixAccount` UIDs/GIDs, home directory storage paths, and group memberships.

---

## 🏛️ Architecture & Control Plane
- **Live Endpoint**: `https://ldap.brain.cs.ait.ac.th` (Production Web & GraphQL)
- **Internal Domain**: `ldap.brain.cs.ait.ac.th`
- **Port `:3890`**: Internal LDAP query port accessible over NetBird WireGuard mesh.
- **Port `:443`**: Traefik-managed HTTPS Web Portal & GraphQL API.
- **GitOps Management**: Provisioned and managed entirely via Declarative Identity-as-Code in [`mgmt/identity/members.yaml`](../../../mgmt/identity/members.yaml) and [`sync_users.py`](../../../mgmt/identity/sync_users.py).

---

## 🚀 Managing Users & Groups
To add, modify, or remove users, edit [`mgmt/identity/members.yaml`](../../../mgmt/identity/members.yaml) and run:

```bash
# Preview diff
python3 mgmt/identity/sync_users.py

# Apply changes to LLDAP via GraphQL API
python3 mgmt/identity/sync_users.py --apply
```
