# TrueNAS Shared NFS Storage (`/mnt/pool-1/home`)

## Overview
All user home directories, persistent datasets, and SSH keys are hosted centrally on TrueNAS (`cairo`) and mounted over NFS across all lab servers.

---

## 1. NFS Client Installation
```bash
sudo apt update
sudo apt install -y nfs-common
```

---

## 2. Mount Point Setup
Create the standard mount target directory:
```bash
sudo mkdir -p /mnt/pool-1/home
```

---

## 3. Persistent `/etc/fstab` Configuration
Add the following entry to `/etc/fstab`:
```text
cairo:/mnt/pool-1/home     /mnt/pool-1/home   nfs     auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0
```

### Mount Parameters Explained:
- `auto,nofail`: Mounts automatically on boot without blocking startup if NAS is temporarily unreachable.
- `noatime`: Optimizes disk I/O performance by skipping read access timestamps.
- `nolock,intr`: Allows operations to be interrupted and prevents file lock deadlocks.
- `actimeo=1800`: Caches directory attributes for 30 minutes to reduce network chatter.

---

## 4. Mounting & Permissions Verification
```bash
# Test mount immediately
sudo mount -a

# Verify mount point
df -h | grep /mnt/pool-1/home

# Verify directory ownership & permissions
ls -la /mnt/pool-1/home/
```

---

## 5. NetBird WireGuard Mesh Auto-Connection on Boot

TrueNAS SCALE is an appliance OS. ZFS pools (`/mnt/pool-1`) are mounted late in the boot sequence, and kernel `iptables` NAT redirection rules are wiped on reboot. To make `cairo` reconnect to the NetBird WireGuard mesh automatically after every reboot:

### Step 1: Deploy the Startup Script
Create `/mnt/pool-1/bin/start-netbird.sh` (or copy from [`start_netbird_cairo.sh`](scripts/start_netbird_cairo.sh)):
```bash
chmod +x /mnt/pool-1/bin/start-netbird.sh
```

### Step 2: Register as a TrueNAS Post-Init Script Task
Run via TrueNAS Shell / SSH (or configure in Web UI under **System Settings -> Advanced -> Init/Shutdown Scripts**):
```bash
midclt call initshutdownscript.create '{
  "type": "SCRIPT",
  "script": "/mnt/pool-1/bin/start-netbird.sh",
  "when": "POSTINIT",
  "enabled": true,
  "timeout": 60,
  "comment": "NetBird Mesh Auto-Connect"
}'
```
This guarantees that after every reboot or TrueNAS upgrade, once `/mnt/pool-1` is mounted, TrueNAS automatically:
1. Re-applies the kernel `iptables REDIRECT` rule to port 33443.
2. Restarts the CSIM forward proxy tunnel.
3. Re-establishes the NetBird WireGuard mesh tunnel to `netbird.brain.cs.ait.ac.th`.
4. Refreshes TrueNAS LDAP directory services.

