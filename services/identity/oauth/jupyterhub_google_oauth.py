"""
JupyterHub Google OAuth Configuration for AIT Brainlab.
Replaces LDAP authenticator with Google OIDC authentication.
"""
import os

c = get_config()  # noqa

c.JupyterHub.authenticator_class = 'oauthenticator.google.GoogleOAuthenticator'

c.GoogleOAuthenticator.client_id = os.environ.get('GOOGLE_CLIENT_ID', '')
c.GoogleOAuthenticator.client_secret = os.environ.get('GOOGLE_CLIENT_SECRET', '')
c.GoogleOAuthenticator.oauth_callback_url = os.environ.get(
    'OAUTH_CALLBACK_URL',
    'https://hub.brain.cs.ait.ac.th/hub/oauth_callback'
)

# Allow all @ait.asia university accounts and approved @gmail.com users
c.GoogleOAuthenticator.hosted_domain = ['ait.asia']
c.GoogleOAuthenticator.allowed_users = {
    'akraradets@gmail.com',
}

c.Authenticator.admin_users = {
    'brainlab@ait.asia',
    'st121413@ait.asia',
    'akraradets@gmail.com',
}
