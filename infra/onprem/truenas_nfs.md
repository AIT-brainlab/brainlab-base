# TrueNAS Shared NFS Storage (`/mnt/HDD/home`)

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
sudo mkdir -p /mnt/HDD/home
```

---

## 3. Persistent `/etc/fstab` Configuration
Add the following entry to `/etc/fstab`:
```text
cairo:/mnt/HDD/home     /mnt/HDD/home   nfs     auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0
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
df -h | grep /mnt/HDD/home

# Verify directory ownership & permissions
ls -la /mnt/HDD/home/
```
