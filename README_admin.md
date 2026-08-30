> [!NOTE]
> **Modern Documentation Notice**:  
> This file contains legacy initial setup notes. For current, production-grade, and modular runbooks, refer to:
> - Base OS & Network: [`infra/onprem/os_setup.md`](infra/onprem/os_setup.md) & [`infra/onprem/network_proxy.md`](infra/onprem/network_proxy.md)
> - TrueNAS NFS & iSCSI: [`infra/onprem/truenas_nfs.md`](infra/onprem/truenas_nfs.md) & [`infra/onprem/truenas_iscsi.md`](infra/onprem/truenas_iscsi.md)
> - SSSD & Identity: [`services/identity/sssd/README.md`](services/identity/sssd/README.md) & [`mgmt/identity/README.md`](mgmt/identity/README.md)
> - JupyterHub: [`services/jupyterhub/README.md`](services/jupyterhub/README.md)
> - NetBird Mesh VPN: [`infra/network/netbird_vpn.md`](infra/network/netbird_vpn.md) & [`mgmt/netbird_setup.md`](mgmt/netbird_setup.md)

This is the historical implementation notes of JupyterHub of the AIT Brainlab.
Below is the step to install a new machine.

# A step to install Ubuntu 22.04 for AIT Brainlab system

- [A step to install Ubuntu 22.04 for AIT Brainlab system](#a-step-to-install-ubuntu-2204-for-ait-brainlab-system)
  - [1. Install Ubuntu 22.04 on the machine](#1-install-ubuntu-2204-on-the-machine)
  - [2. Configuring IP address, proxy, and /etc/hosts](#2-configuring-ip-address-proxy-and-etchosts)
    - [2-1. Configuring NTP](#2-1-configuring-ntp)
    - [2-2. Configuring proxy](#2-2-configuring-proxy)
  - [3. Set Proxy for APT, update, and upgrade](#3-set-proxy-for-apt-update-and-upgrade)
  - [4. Set locale](#4-set-locale)
  - [5. Install Nvidia driver via `Software & Updates` app](#5-install-nvidia-driver-via-software--updates-app)
  - [6. Configuring NAS for `home`](#6-configuring-nas-for-home)
  - [7. Connect to LDAP](#7-connect-to-ldap)
  - [8. Install Docker](#8-install-docker)
  - [9. Configuring Docker with Proxy](#9-configuring-docker-with-proxy)
  - [10. Set rootless mode](#10-set-rootless-mode)
  - [11. Install Nvidia Container Toolkit](#11-install-nvidia-container-toolkit)
- [12. Install Python](#12-install-python)
  - [13. Set up Jupyterhub](#13-set-up-jupyterhub)
  - [14. Set DockerSpawner](#14-set-dockerspawner)
  - [15. Set Ldap Authentication](#15-set-ldap-authentication)
  - [16. add runtime nvidia](#16-add-runtime-nvidia)
  - [17. register jupyterhub service to systemd](#17-register-jupyterhub-service-to-systemd)


## 1. Install Ubuntu 22.04 on the machine
## 2. Configuring IP address, proxy, and /etc/hosts
### 2-1. Configuring NTP
https://ubuntu.com/server/docs/network-ntp

The NTP domain of CSIM is `ntp.cs.ait.ac.th`.
Thus add the following configuration to `/etc/systemd/timesyncd.conf`
```sh
[Time]
NTP=ntp.cs.ait.ac.th
FallbackNTP=ntp.ubuntu.com
RootDistanceMaxSec=5
PollIntervalMinSec=32
PollIntervalMaxSec=2048
```
Use `timedatectl` to check the active configuration and `systemctl restart systemd-timesyncd.service` to restart the service.

To change time zone use this commad

```sh
sudo timedatectl set-timezone Asia/Bangkok
```

### 2-2. Configuring proxy
https://stackoverflow.com/questions/34021485/issue-on-making-requests-through-proxy-when-using-sudo-command

The `http_proxy` and `https_proxy` should be set for both user and sudoers file.

First, configuring `.bashrc` with

```sh
export http_proxy=http://192.41.170.82:3128
export https_proxy=http://192.41.170.82:3128
```

Then, to keep the environment variables for the `sudo` command, do the following

```sh
$ sudo visudo
```

add this line

```sh
Defaults env_keep += "ftp_proxy http_proxy https_proxy no_proxy"
```

save and it should just work

## 3. Set Proxy for APT, update, and upgrade
https://www.howtoforge.com/how-to-setup-apt-proxy-on-ubuntu/
## 4. Set locale
```sh
sudo apt-get install -y locales
sudo locale-gen en_US.UTF-8
sudo update-locale LC_TIME=en_US.UTF-8
```
## 5. Install Nvidia driver via `Software & Updates` app
or using Ubuntu-Driver https://help.ubuntu.com/community/NvidiaDriversInstallation
## 6. Configuring NAS for `home`
```shell
sudo apt install -y nfs-common
sudo mkdir -p /mnt/pool-1/home
```
add mount command to `/etc/fstab`
```shell
cairo:/mnt/pool-1/home     /mnt/pool-1/home   nfs     auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0
```
Then try to mount with
```
sudo mount -a
```

## 7. Connect to LDAP
https://bobcares.com/blog/configure-ldap-client-ubuntu/

In `/etc/pam.d/common-password`, use the following config.

```sh
password        requisite                       pam_pwquality.so retry=3
password        [success=1 default=ignore]      pam_ldap.so use_authtok ignore_unknown_user ignore_authinfo_unavail no_warn minimum_uid=1000
password        requisite                       pam_deny.so
password        required                        pam_permit.so
password        optional                        pam_gnome_keyring.so
```
This will allow the local machine to reset the LDAP password

## 8. Install Docker

Install from the script.

```sh
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

##  9. Configuring Docker with Proxy
https://docs.docker.com/config/daemon/systemd/

##  10. Set rootless mode
https://docs.docker.com/engine/security/rootless/

- https://docs.docker.com/engine/security/rootless/#exposing-privileged-ports
- https://docs.docker.com/engine/security/rootless/#limiting-resources

## 11. Install Nvidia Container Toolkit
https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html

```sh
distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
      && curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
      && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
```

```sh
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker
systemctl --user restart docker.service
```

# 12. Install Python

```sh
sudo apt install -y python3 python3-pip
```

## 13. Set up Jupyterhub
https://jupyterhub.readthedocs.io/en/stable/tutorial/quickstart.html

```sh
sudo apt install -y nodejs npm
sudo pip3 install jupyterhub
sudo npm install -g configurable-http-proxy
sudo pip3 install jupyterlab notebook 
```

## 14. Set DockerSpawner

```sh
sudo pip3 install dockerspawner
```

## 15. Set Ldap Authentication

```sh
sudo pip3 install jupyterhub-ldapauthenticator
```

Modify the package to fix TLS errors when authentication

```sh
cd /usr/local/lib/python3.10/dist-packages/ldapauthenticator
sudo vim ldapauthenticator.py
# line 312
# ldap3.AUTO_BIND_NO_TLS if self.use_ssl else ldap3.AUTO_BIND_TLS_BEFORE_BIND
ldap3.AUTO_BIND_NO_TLS if not self.use_ssl else ldap3.AUTO_BIND_TLS_BEFORE_BIND
```

## 16. add runtime nvidia
https://hackmd.io/@DanielChen/Sy81P-Aw4?type=viewe

```sh
sudo vim /etc/docker/daemon.json

{
        "data-root": "/data/docker",
        "runtimes": {
                "nvidia": {
                        "path": "nvidia-container-runtime",
                        "runtimeArgs": []
                }
        }
}
```

##  17. register jupyterhub service to systemd

https://medium.com/analytics-vidhya/auto-start-jupyter-lab-on-machine-boot-e4f6b3296034

create a systemd file
```sh
sudo vim jupyterhub.service

[Unit]
Description=JupyterHub
Wants=network-online.target
After=syslog.target network.target network-online.target

[Service]
User=root
Environment="PATH=/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/projects/jupyter/"
# use this `openssl rand -hex 32` to obtain key
Environment=JUPYTERHUB_CRYPT_KEY=
ExecStart=/usr/local/bin/jupyterhub -f /root/projects/jupyter/jupyterhub_config.py

[Install]
WantedBy=multi-user.target
```

symlink the file to systemd
```sh
sudo ln -s /root/projects/jupyter/systemd/jupyterhub.service  /etc/systemd/system/jupyterhub.service
```

reload systemctl
```sh
sudo systemctl daemon-reload
```

Try start the service
```sh
sudo systemctl start jupyterhub.service
```

Enable auto boot
```sh
sudo systemctl enable jupyterhub.service
```
