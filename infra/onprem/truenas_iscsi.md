# TrueNAS Shared iSCSI Block Storage (`/mnt/docker-root`)

## Overview
High-performance 1 TB block storage volume provided by TrueNAS (`cairo`) over iSCSI and mounted on `la` at `/mnt/docker-root` for Docker daemon images, container layers, and JupyterHub persistent runner overhead.

---

## 1. Network & Target Topology
- **Storage Target**: TrueNAS SCALE (`cairo`)
- **Portal IP**: `192.41.170.4:3260` (High-speed CSIM server LAN)
- **Target IQN**: `iqn.2005-10.org.freenas.ctl:docker-root`
- **Initiator Node (`la`)**: `iqn.2004-10.com.ubuntu:01:29e9cb988f8`
- **Filesystem UUID**: `65c62d37-37fa-405d-a507-16c73a42ee6a`
- **Mount Point**: `/mnt/docker-root`

---

## 2. Client Setup & Authentication on `la`

### Prerequisites
```bash
sudo apt update
sudo apt install -y open-iscsi
```

### Discovery & Automated Login
```bash
# Discover target on cairo
sudo iscsiadm -m discovery -t sendtargets -p 192.41.170.4:3260

# Set automatic login on system boot
sudo iscsiadm -m node -T iqn.2005-10.org.freenas.ctl:docker-root -p 192.41.170.4:3260 --op=update -n node.startup -v automatic

# Manual login test
sudo iscsiadm -m node -T iqn.2005-10.org.freenas.ctl:docker-root -p 192.41.170.4:3260 --login
```

---

## 3. Persistent `/etc/fstab` Configuration
The mount entry in `/etc/fstab` on `la` **must** include `_netdev` so systemd waits for network initialization and the open-iscsi daemon before mounting:

```text
UUID=65c62d37-37fa-405d-a507-16c73a42ee6a  /mnt/docker-root  ext4  rw,suid,_netdev,exec,auto,nouser,async  0  2
```

---

## 4. Operational Verification
```bash
# Check active iSCSI session
sudo iscsiadm -m session

# Verify block device and mount
lsblk -f | grep 65c62d37
df -h /mnt/docker-root
```
