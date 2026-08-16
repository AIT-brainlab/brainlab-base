server_ip = '192.41.170.85'
domain_name = 'la.cs.ait.ac.th'
# "name_for_web_render":"Actual image name in docker"
image_list = {
    "default environment":"default_env",
    "NLP":"nlp",
    "Computer Vision":"cv",
    "akraradets":"akraradets",
    "custom1":"custom1",
    "custom2":"custom2",
    "custom3":"custom3",
    "custom4":"custom4",
    "custom5":"custom5",
    }
proxy_address = "http://192.41.170.23:3128"

# Configuration file for jupyterhub.

c = get_config()  #noqa
c.JupyterHub.ssl_cert = f"/etc/letsencrypt/live/{domain_name}/fullchain.pem"
c.JupyterHub.ssl_key = f"/etc/letsencrypt/live/{domain_name}/privkey.pem"
c.JupyterHub.ip = '0.0.0.0'
c.JupyterHub.port = 443
c.JupyterHub.hub_ip = server_ip
# Server won't restart when jupyterhub is gone
c.JupyterHub.cleanup_servers = False

c.Authenticator.admin_users = set({'admin'})
c.Authenticator.enable_auth_state = True
c.JupyterHub.authenticator_class = 'ldapauthenticator.LDAPAuthenticator'
c.LDAPAuthenticator.server_address= 'ldap.brainlab'
c.LDAPAuthenticator.lookup_dn = False
c.LDAPAuthenticator.bind_dn_template = [
    "uid={username},ou=people,dc=ldap,dc=brainlab",
]
c.LDAPAuthenticator.use_ssl = False


import dockerspawner
class DockerSpawner(dockerspawner.DockerSpawner):
    def create_object(self):
        env = self.get_env()
        ssh_port = env['NB_SSH_PORT']
        self.extra_create_kwargs["ports"] = {
            f"{self.port}/tcp": None,
            f"{22}/tcp": None,
        }
        self.extra_host_config["port_bindings"] = {
            self.port: (self.host_ip,),
            22: ("0.0.0.0",ssh_port),
        }

        import docker
        device_ids=["0"]
        if(env["NB_USER"] in ['bci','aimanl']):
            device_ids=["1"]
        gpus = docker.types.DeviceRequest(device_ids=device_ids, capabilities=[['gpu']])
        self.extra_host_config["device_requests"] = [gpus]
        return super().create_object()

c.JupyterHub.spawner_class = DockerSpawner

c.DockerSpawner.allowed_images = image_list
c.JupyterHub.hub_ip = server_ip
c.DockerSpawner.volumes = {
        '/mnt/HDD/home/{username}/work':'/home/{username}/work',
        '/mnt/HDD/home/{username}/.ssh':'/home/{username}/.ssh'
        }
c.DockerSpawner.extra_create_kwargs = {'user': 'root'}
c.DockerSpawner.extra_host_config = {'runtime': 'nvidia', 'ipc_mode':'host'}
c.DockerSpawner.remove = True

c.Spawner.environment = dict({})
c.Spawner.environment['GRANT_SUDO'] = 'yes'
c.Spawner.environment['CHOWN_HOME'] = 'yes'
c.Spawner.environment['http_proxy'] = proxy_address
c.Spawner.environment['https_proxy'] = proxy_address

from ldapauthenticator import LDAPAuthenticator

class LDAPAuthenticatorInfo(LDAPAuthenticator):
    async def pre_spawn_start(self, user, spawner):
        auth_state = await user.get_auth_state()
        self.log.warning(f"pre_spawn_start auth_state: {auth_state}")
        if not auth_state:
            return

        # Setup environment variables to pass to singleuser server
        # The test server doesn't have numeric UIDs, so create one by hashing uid
        spawner.environment["NB_UID"] = auth_state["uidNumber"][0]
        spawner.environment["NB_USER"] = auth_state["uid"][0]
        spawner.environment["NB_SSH_PORT"] = auth_state["jupyterSshPort"][0]


c.LDAPAuthenticator.auth_state_attributes = ["uid", "uidNumber", "gidNumber", "jupyterSshPort"]
c.JupyterHub.authenticator_class = LDAPAuthenticatorInfo
