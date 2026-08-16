# Core Identity Service: `lldap` (`mgmt/services/identity`)

## Overview
`lldap` manages Unix `posixAccount` UIDs/GIDs for lab members. This ensures TrueNAS NFS file permissions (`cairo:/mnt/HDD/home`) and SSH logins remain identical across physical and cloud nodes.

---

## 1. Quickstart Deployment
```bash
docker compose up -d
```
Access the admin portal at `http://<HOST_IP>:17170`.

---

## 2. Directory Schema
- **Base DN**: `dc=brain,dc=cs,dc=ait,dc=ac,dc=th`
- **LDAP Port**: `3890` (or `389`)
- **Web UI Port**: `17170`

---

## 3. Client Configuration
Distribute `sssd.conf.template` to `/etc/sssd/sssd.conf` on compute nodes and NAS `cairo`.
