# ==============================================================================
# 🚀 AIT Brainlab - Production JupyterHub Configuration
# ==============================================================================
# Architecture:
#   - AuthN: Google OAuth2 (GoogleOAuthenticator) allowing @ait.asia, @ait.ac.th,
#     and approved alumni @gmail.com accounts.
#   - AuthZ: Cloud LLDAP Directory (ldap://ldap.brain.cs.ait.ac.th:3890) queried over
#     encrypted NetBird WireGuard mesh tunnel to map email -> POSIX UID/GID/username.
#   - Spawner: DockerSpawner allocating dual NVIDIA RTX A6000 GPUs, hardware limits,
#     and auto-mounting TrueNAS NFS user work directories.
#   - Edge Proxy: Traefik terminating TLS on port 443 with Let's Encrypt certificates.
# ==============================================================================

import os
import docker
import ldap3
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
# 2. Authentication: Google OAuth2 (AuthN)
# ------------------------------------------------------------------------------
c.JupyterHub.authenticator_class = GoogleOAuthenticator

c.GoogleOAuthenticator.client_id = os.environ.get('GOOGLE_CLIENT_ID', '')
c.GoogleOAuthenticator.client_secret = os.environ.get('GOOGLE_CLIENT_SECRET', '')
c.GoogleOAuthenticator.oauth_callback_url = os.environ.get(
    'OAUTH_CALLBACK_URL',
    'https://la.cs.ait.ac.th/hub/oauth_callback'
)

# University domain accounts allowed automatically
c.GoogleOAuthenticator.hosted_domain = ['ait.asia', 'ait.ac.th']

# Specific approved alumni & administrative Google accounts
c.GoogleOAuthenticator.allowed_users = {
    'brainlab@ait.asia',
    'akraradets@gmail.com',
    'akraradet.s@gmail.com',
}

# Administrative users
c.Authenticator.admin_users = {
    'brainlab@ait.asia',
    'st121413@ait.asia',
    'akraradets@gmail.com',
}
c.Authenticator.enable_auth_state = True

# ------------------------------------------------------------------------------
# 3. Authorization & POSIX Mapping: Cloud LLDAP Directory (AuthZ)
# ------------------------------------------------------------------------------
LLDAP_URL = os.environ.get('LLDAP_URL', 'ldap://ldap.brain.cs.ait.ac.th:3890')
LLDAP_BIND_DN = os.environ.get('LLDAP_BIND_DN', 'uid=ldapservice,ou=people,dc=brain,dc=cs,dc=ait,dc=ac,dc=th')
LLDAP_PASSWORD = os.environ.get('LLDAP_PASSWORD', '')
LLDAP_BASE_DN = 'dc=brain,dc=cs,dc=ait,dc=ac,dc=th'

def query_lldap_user(email):
    """Queries LLDAP over NetBird to map an email address to POSIX uid, uidNumber, and gidNumber."""
    try:
        server = ldap3.Server(LLDAP_URL, get_info=ldap3.NONE, connect_timeout=5)
        conn = ldap3.Connection(server, user=LLDAP_BIND_DN, password=LLDAP_PASSWORD, auto_bind=True)
        # Search by email attribute
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
# 4. Spawner: DockerSpawner with Dual RTX A6000 & TrueNAS NFS
# ------------------------------------------------------------------------------
CSIM_PROXY = "http://192.41.170.82:3128"

class BrainlabDockerSpawner(dockerspawner.DockerSpawner):
    async def pre_spawn_start(self, user, spawner):
        email = user.name
        ldap_info = query_lldap_user(email)

        if ldap_info:
            posix_user = ldap_info['username']
            posix_uid = ldap_info['uid']
            posix_gid = ldap_info['gid']
        else:
            # Safe fallback if not found in directory
            posix_user = email.split('@')[0]
            posix_uid = 2000
            posix_gid = 2008

        # Inject POSIX UID & GID for accurate file permissions
        spawner.environment['NB_USER'] = posix_user
        spawner.environment['NB_UID'] = str(posix_uid)
        spawner.environment['NB_GID'] = str(posix_gid)
        spawner.environment['CHOWN_HOME'] = 'yes'
        spawner.environment['GRANT_SUDO'] = 'yes'

        # CSIM proxy configuration for outbound internet inside container
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