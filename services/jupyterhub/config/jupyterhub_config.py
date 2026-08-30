# ==============================================================================
# 🚀 AIT Brainlab - Production JupyterHub Configuration
# ==============================================================================
# Architecture:
#   - AuthN: Google OAuth2 (GoogleOAuthenticator) for identity verification.
#   - AuthZ: Cloud LLDAP Directory (ldap://ldap.brain.cs.ait.ac.th:3890) queried over
#     encrypted NetBird WireGuard mesh tunnel to dynamically authorize members
#     and map email -> POSIX username, UID, GID, and TrueNAS home directory.
#   - Spawner: DockerSpawner allocating dual NVIDIA RTX A6000 GPUs, hardware limits,
#     and auto-mounting TrueNAS NFS user work directories.
#   - Edge Proxy: Traefik terminating TLS on port 443 with Let's Encrypt certificates.
# ==============================================================================

import os
import docker
import ldap3
from tornado import web
from oauthenticator.google import GoogleOAuthenticator
import dockerspawner

c = get_config()  # noqa

# ------------------------------------------------------------------------------
# 1. Hub Networking & Persistence
# ------------------------------------------------------------------------------
c.JupyterHub.hub_ip = '0.0.0.0'
c.JupyterHub.hub_port = 8081
c.JupyterHub.hub_connect_ip = 'jupyterhub'
c.JupyterHub.port = 8000
c.JupyterHub.cleanup_servers = False
c.JupyterHub.db_url = 'sqlite:////data/jupyterhub.sqlite'

# ------------------------------------------------------------------------------
# 2. Cloud LLDAP Directory Query Helper (AuthZ)
# ------------------------------------------------------------------------------
LLDAP_URL = os.environ.get('LLDAP_URL', 'ldap://ldap.brain.cs.ait.ac.th:3890')
LLDAP_BIND_DN = os.environ.get('LLDAP_BIND_DN', 'uid=ldapservice,ou=people,dc=brain,dc=cs,dc=ait,dc=ac,dc=th')
LLDAP_PASSWORD = os.environ.get('LLDAP_PASSWORD', '')
LLDAP_BASE_DN = 'dc=brain,dc=cs,dc=ait,dc=ac,dc=th'

def query_lldap_user(email):
    """Queries LLDAP over NetBird to map an email address to POSIX uid, uidNumber, and gidNumber."""
    if not email or not LLDAP_PASSWORD:
        return None
    try:
        server = ldap3.Server(LLDAP_URL, get_info=ldap3.NONE, connect_timeout=5)
        conn = ldap3.Connection(server, user=LLDAP_BIND_DN, password=LLDAP_PASSWORD, auto_bind=True)
        # Search by email attribute in LLDAP
        search_filter = f"(&(objectClass=posixAccount)(mail={email}))"
        conn.search(
            search_base=f"ou=people,{LLDAP_BASE_DN}",
            search_filter=search_filter,
            attributes=['uid', 'uidNumber', 'gidNumber', 'homeDirectory']
        )
        if conn.entries:
            entry = conn.entries[0]
            return {
                'username': str(entry.uid.value),
                'uid': int(entry.uidNumber.value),
                'gid': int(entry.gidNumber.value),
                'home': str(entry.homeDirectory.value) if 'homeDirectory' in entry else f"/mnt/pool-1/home/{entry.uid.value}"
            }
    except Exception as e:
        print(f"⚠ LLDAP query error for {email}: {e}")
    return None

# ------------------------------------------------------------------------------
# 3. Dynamic LLDAP Authenticator (Google AuthN + LLDAP AuthZ)
# ------------------------------------------------------------------------------
class BrainlabAuthenticator(GoogleOAuthenticator):
    """Authenticates via Google OAuth, then authorizes strictly against LLDAP members."""
    async def authenticate(self, handler, data=None):
        auth_model = await super().authenticate(handler, data)
        if not auth_model:
            return None

        # Resolve Google authenticated email
        email = auth_model.get('name')
        if not email and 'auth_state' in auth_model:
            email = auth_model['auth_state'].get('google_user', {}).get('email')

        # Check authorization dynamically against Cloud LLDAP
        ldap_info = query_lldap_user(email)
        if not ldap_info:
            self.log.warning(f"❌ Authorization Denied: {email} not found in LLDAP directory.")
            raise web.HTTPError(
                403,
                f"Access Denied: Your Google account ({email}) is not registered in the AIT Brainlab directory. "
                "Please contact the lab administrator to be enrolled in members.yaml."
            )

        posix_username = ldap_info['username']
        self.log.info(
            f"✔ Authorization Granted: {email} -> POSIX '{posix_username}' "
            f"(UID: {ldap_info['uid']}, GID: {ldap_info['gid']})"
        )

        # Normalize JupyterHub internal username to their POSIX username (e.g. akraradets, st121413)
        auth_model['name'] = posix_username
        if 'auth_state' not in auth_model or not auth_model['auth_state']:
            auth_model['auth_state'] = {}
        auth_model['auth_state']['posix'] = ldap_info

        return auth_model

    async def check_allowed(self, username, auth_model):
        # Already verified in authenticate() via LLDAP
        return True

c.JupyterHub.authenticator_class = BrainlabAuthenticator

c.GoogleOAuthenticator.client_id = os.environ.get('GOOGLE_CLIENT_ID', '')
c.GoogleOAuthenticator.client_secret = os.environ.get('GOOGLE_CLIENT_SECRET', '')
c.GoogleOAuthenticator.oauth_callback_url = os.environ.get(
    'OAUTH_CALLBACK_URL',
    'https://la.cs.ait.ac.th/hub/oauth_callback'
)

# Admin users (POSIX usernames matching members.yaml)
c.Authenticator.admin_users = {
    'bci',
    'akraradets',
}
c.Authenticator.enable_auth_state = True

# ------------------------------------------------------------------------------
# 4. Spawner: DockerSpawner with Dual RTX A6000 & TrueNAS NFS
# ------------------------------------------------------------------------------
CSIM_PROXY = "http://192.41.170.82:3128"

class BrainlabDockerSpawner(dockerspawner.DockerSpawner):
    async def pre_spawn_start(self, user, spawner):
        auth_state = await user.get_auth_state()
        posix_info = auth_state.get('posix') if auth_state else None

        if not posix_info:
            raise web.HTTPError(
                500,
                f"Failed to spawn container: POSIX attributes for user '{user.name}' were not found in LLDAP."
            )

        posix_user = posix_info['username']
        posix_uid = posix_info['uid']
        posix_gid = posix_info['gid']

        # Inject POSIX UID & GID for accurate file permissions on TrueNAS
        spawner.environment['NB_USER'] = posix_user
        spawner.environment['NB_UID'] = str(posix_uid)
        spawner.environment['NB_GID'] = str(posix_gid)
        spawner.environment['CHOWN_HOME'] = 'yes'
        spawner.environment['GRANT_SUDO'] = 'yes'

        # CSIM proxy configuration for outbound internet inside student container
        spawner.environment['http_proxy'] = CSIM_PROXY
        spawner.environment['https_proxy'] = CSIM_PROXY
        spawner.environment['HTTP_PROXY'] = CSIM_PROXY
        spawner.environment['HTTPS_PROXY'] = CSIM_PROXY

        # Mount TrueNAS NFS work directories and shared datasets
        spawner.volumes = {
            f"/mnt/pool-1/home/{posix_user}/work": f"/home/{posix_user}/work",
            f"/mnt/pool-1/home/{posix_user}/.ssh": f"/home/{posix_user}/.ssh",
            "/mnt/Dataset": f"/home/{posix_user}/Dataset",
            "/mnt/dataset_arch": f"/home/{posix_user}/dataset_arch",
        }

    def create_object(self):
        # Pass dual NVIDIA RTX A6000 GPUs
        device_ids = ["0,1"]
        gpus = docker.types.DeviceRequest(device_ids=device_ids, capabilities=[['gpu']])
        self.extra_host_config["device_requests"] = [gpus]
        return super().create_object()

c.JupyterHub.spawner_class = BrainlabDockerSpawner

# Spawner network & container settings
c.DockerSpawner.network_name = 'jupyterhub-net'
c.DockerSpawner.extra_create_kwargs = {'user': 'root'}
c.DockerSpawner.extra_host_config = {
    'runtime': 'nvidia',
    'ipc_mode': 'host',
    'pid_mode': 'host'
}
c.DockerSpawner.remove = True

# Hardware resource quotas per user
c.Spawner.mem_limit = '40G'
c.Spawner.cpu_limit = 16

# ------------------------------------------------------------------------------
# 5. Notebook Images Menu
# ------------------------------------------------------------------------------
c.DockerSpawner.allowed_images = {
    "Default Environment (PyTorch / Data Science)": "default",
    "NLP (Natural Language Processing & LLMs)": "nlp",
    "Computer Vision (OpenCV & Albumentations)": "cv",
    "CUDA 11.6.1 (Ubuntu 20.04 Legacy)": "cuda11.6.1-20.04",
}