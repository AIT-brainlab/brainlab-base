# Google OAuth2 / OIDC Single Sign-On

## Overview
Allows members with `@ait.asia` (Google Workspace) and `@gmail.com` accounts to log into JupyterHub with 1-click Google authentication.

## Setup
1. Create OAuth2 Client ID & Secret in GCP Console (`ait-brainlab-mgmt` $\rightarrow$ **APIs & Services** $\rightarrow$ **Credentials**).
2. Set `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` environment variables on the JupyterHub server.
3. Reference `jupyterhub_google_oauth.py` in your JupyterHub launch script.
