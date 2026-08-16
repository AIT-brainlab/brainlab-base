"""
JupyterHub Google OAuth Configuration for AIT Brainlab.
Replaces LDAP authenticator with Google OIDC authentication.
"""
import os

# Enable Google Authenticator
c = get_config()  # noqa

c.JupyterHub.authenticator_class = 'oauthenticator.google.GoogleOAuthenticator'

# OAuth2 credentials (set via environment variables)
c.GoogleOAuthenticator.client_id = os.environ.get('GOOGLE_CLIENT_ID', '')
c.GoogleOAuthenticator.client_secret = os.environ.get('GOOGLE_CLIENT_SECRET', '')
c.GoogleOAuthenticator.oauth_callback_url = os.environ.get(
    'OAUTH_CALLBACK_URL',
    'https://hub.brain.cs.ait.ac.th/hub/oauth_callback'
)

# Email Whitelist & Domain Restriction
c.GoogleOAuthenticator.hosted_domain = ['ait.asia'] # Allow all @ait.asia users
c.GoogleOAuthenticator.allowed_users = {
    # Approved external @gmail.com collaborators
    'akraradets@gmail.com',
}

# Admin users
c.Authenticator.admin_users = {
    'brainlab@ait.asia',
    'st121413@ait.asia',
    'akraradets@gmail.com',
}
