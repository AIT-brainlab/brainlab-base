# Google OAuth2 / OIDC Integration

## Overview
Allows members with `@ait.asia` (university Google Workspace) and `@gmail.com` accounts to log in with 1 click to JupyterHub and other lab web services.

## Setup Steps
1. In GCP Console $\rightarrow$ **APIs & Services** $\rightarrow$ **Credentials** in project `ait-brainlab-mgmt`:
   - Create **OAuth 2.0 Client ID** (Web application).
   - Authorized redirect URI: `https://hub.brain.cs.ait.ac.th/hub/oauth_callback`.
2. Install `oauthenticator`:
   ```bash
   pip install oauthenticator
   ```
3. Set environment variables:
   ```bash
   export GOOGLE_CLIENT_ID="<YOUR_CLIENT_ID>"
   export GOOGLE_CLIENT_SECRET="<YOUR_CLIENT_SECRET>"
   ```
4. Include `jupyterhub_google_oauth.py` in your JupyterHub config.
