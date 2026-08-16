# `lldap` Lightweight Directory Service

## Overview
`lldap` replaces the legacy heavy OpenLDAP server. It manages Unix `posixAccount` UIDs/GIDs for lab members so that NFS NAS file permissions on `cairo:/mnt/HDD/home` and Linux SSH logins remain consistent across on-prem and cloud machines.

## Deployment Options

### Option A: GCP Cloud Run (Serverless)
Deploy container to GCP Cloud Run with a persistent Cloud Storage volume or Cloud SQL database.

### Option B: Management VM / Container
Run using Docker Compose:
```bash
cp lldap_config.toml.example lldap_config.toml
# Fill in secrets
docker compose up -d
```

## Base DN & Attributes
- **Base DN**: `dc=brain,dc=cs,dc=ait,dc=ac,dc=th`
- **User ObjectClass**: `posixAccount`, `person`, `inetOrgPerson`
- **Port**: `3890` (LDAP) / `17170` (Web Admin UI)
