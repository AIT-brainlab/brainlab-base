# Identity & Access Management Domain (`services/identity`)

## Overview
The **Identity Domain** manages user directories, POSIX UID/GID mapping, SSH PAM integration, and Single Sign-On (SSO) across on-premise compute nodes, TrueNAS storage, and cloud web applications.

---

## 🏗 Sub-Services

| Component | Technology | Target / Purpose |
| :--- | :--- | :--- |
| [**`lldap/`**](lldap/README.md) | Rust Lightweight LDAP | POSIX UID/GID mapping for Linux SSSD & NAS file permissions |
| [**`oauth/`**](oauth/README.md) | Google OAuth2 / OIDC | 1-click Google login for JupyterHub & web platforms |
| [**`sssd/`**](sssd/README.md) | Linux SSSD Client | Client-side LDAP authentication & local user resolution |
