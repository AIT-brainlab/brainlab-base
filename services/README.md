# Services Domain (`services/`)

The **Services Domain** encompasses all user-facing applications, computing environments, machine learning platforms, and APIs running on top of the physical and cloud infrastructure.

---

## 🚀 Services Index

| Service Directory | Description | Primary URL / Port |
| :--- | :--- | :--- |
| [**`services/jupyterhub/`**](jupyterhub/README.md) | Multi-user GPU JupyterLab container environment | `https://hub.brain.cs.ait.ac.th` |
| [**`services/identity/`**](identity/README.md) | User directory (`lldap`), Google OAuth SSO, and SSSD | `https://authen.brain.cs.ait.ac.th` |
| [**`services/mlflow/`**](mlflow/README.md) | Model training tracking, metrics logging, and artifact store | `http://tokyo.cs.ait.ac.th:5000` |
| [**`services/printing/`**](printing/README.md) | Remote Web Print Portal (`docker-cups`) bridging cloud to CSIM printer | `https://print.brain.cs.ait.ac.th` |
| [**`services/api/`**](api/README.md) | Traefik reverse proxy and deployed demo apps & APIs | `https://tokyo.cs.ait.ac.th` |
