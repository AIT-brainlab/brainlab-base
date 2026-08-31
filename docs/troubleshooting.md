# SysAdmin Troubleshooting Runbook

## Overview
Quick reference for diagnosing and resolving the most frequent operational incidents in AIT Brainlab.

---

## 1. Issue: NVIDIA GPU Not Detected / CUDA Errors
### Symptoms:
- `nvidia-smi` returns `NVIDIA-SMI has failed because it couldn't communicate with the NVIDIA driver.`
- Jupyter container fails with `docker: Error response from daemon: could not select device driver "" with capabilities: [[gpu]]`.

### Resolution:
1. Verify kernel modules:
   ```bash
   lsmod | grep nvidia
   ```
2. Restart NVIDIA Container Toolkit & Docker:
   ```bash
   sudo systemctl restart nvidia-container-toolkit || true
   sudo systemctl restart docker
   ```
3. If kernel was updated via `apt upgrade`, recompile / reinstall drivers:
   ```bash
   sudo ubuntu-drivers install --gpgpu
   sudo reboot
   ```

---

## 2. Issue: TrueNAS NFS Mount Becomes Stale
### Symptoms:
- `ls /mnt/pool-1/home` hangs indefinitely or returns `Stale file handle`.

### Resolution:
1. Force unmount the stale mount:
   ```bash
   sudo umount -l /mnt/pool-1/home
   ```
2. Verify NAS connectivity:
   ```bash
   ping -c 3 cairo
   showmount -e cairo
   ```
3. Remount:
   ```bash
   sudo mount -a
   ```

---

## 3. Issue: Outbound Requests Failing (Proxy Timeout)
### Symptoms:
- `pip install` or `apt update` hangs or errors with connection refused.

### Resolution:
1. Verify CSIM proxy reachability:
   ```bash
   curl -I --proxy http://192.41.170.82:3128 https://www.google.com
   ```
2. Ensure proxy environment variables are exported in current subshell:
   ```bash
   export http_proxy=http://192.41.170.82:3128
   export https_proxy=http://192.41.170.82:3128
   export no_proxy="localhost,127.0.0.1,192.41.170.0/24,100.74.0.0/16,*.ait.ac.th,*.ait.asia,*.brain.cs.ait.ac.th"
   ```

---

## 4. Issue: JupyterHub Fails to Spawn User Container
### Symptoms:
- Spawner times out or throws HTTP 500 error.

### Resolution:
1. Check JupyterHub logs:
   ```bash
   sudo journalctl -u jupyterhub.service -n 50 --no-pager
   ```
2. Verify user home directory exists and permissions match:
   ```bash
   ls -ld /mnt/pool-1/home/<username>/work
   ```
3. Manually remove stuck container if present:
   ```bash
   docker rm -f jupyter-<username>
   ```

---

## 5. Issue: SSSD User or Group Resolution Failure
### Symptoms:
- `id <username>` fails or returns `no such user`.
- Permission denied writing to TrueNAS home directory.

### Resolution:
1. Check SSSD service status:
   ```bash
   sudo systemctl status sssd
   ```
2. Purge SSSD cache and restart:
   ```bash
   sudo sss_cache -E
   sudo systemctl restart sssd
   ```
3. Test LDAP reachability over NetBird WireGuard mesh:
   ```bash
   ldapsearch -x -H ldap://brainlab-mgmt-vm:3890 -D "uid=ldapservice,ou=people,dc=brain,dc=cs,dc=ait,dc=ac,dc=th" -W -b "dc=brain,dc=cs,dc=ait,dc=ac,dc=th" "(uid=<username>)"
   ```

---

## 6. Issue: NetBird Mesh Disconnected on On-Prem Node
### Symptoms:
- `netbird status` shows `Management: Disconnected` or `Signal: Disconnected`.

### Resolution:
1. Check if CSIM proxy CONNECT tunnel is running:
   ```bash
   sudo systemctl status netbird-proxy-tunnel.service
   ```
2. Restart proxy tunnel and NetBird client:
   ```bash
   sudo systemctl restart netbird-proxy-tunnel.service
   sudo systemctl restart netbird.service
   netbird status
   ```

---

## 7. Issue: TrueNAS iSCSI `/mnt/docker-root` Unmounted
### Symptoms:
- Docker fails to start with error locating `/mnt/docker-root`.
- `df -h /mnt/docker-root` returns empty or root filesystem.

### Resolution:
1. Check active iSCSI sessions:
   ```bash
   sudo iscsiadm -m session
   ```
2. If inactive, re-login to TrueNAS target:
   ```bash
   sudo iscsiadm -m node -T iqn.2005-10.org.freenas.ctl:docker-root -p 192.41.170.4:3260 --login
   sudo mount -a
   df -h /mnt/docker-root
   ```

---

## 8. Issue: Proxmox VE Kernel Upgrade Failure (`/boot/efi` No space left on device)
### Symptoms:
- `apt upgrade` fails with:
  `Failed to make directory '/boot/efi/...': No space left on device`
- `dpkg: error processing package initramfs-tools (--configure)`
- `/boot/efi` shows 100% usage under `df -h /boot/efi`.

### Root Cause:
Proxmox nodes booted via UEFI `systemd-boot` store kernel binaries and initramfs images directly inside the EFI System Partition (`/boot/efi/<machine-id>/<version>/`). Over time, accumulated old kernels fill the 1GB ESP partition, blocking `update-initramfs`.

### Resolution:
1. Verify currently active running kernel (**NEVER delete this version!**):
   ```bash
   uname -r
   ```
2. List kernel folders in the EFI partition:
   ```bash
   ls -lh /boot/efi/<machine-id>/
   ```
3. Safely prune several older, non-running kernel directories:
   ```bash
   rm -rf /boot/efi/<machine-id>/<OLD-KERNEL-VERSION>
   ```
4. Complete the interrupted package configuration:
   ```bash
   dpkg --configure -a
   ```
5. Clean up old Debian kernel packages and refresh systemd-boot:
   ```bash
   apt autoremove --purge -y
   proxmox-boot-tool clean 2>/dev/null || true
   proxmox-boot-tool refresh 2>/dev/null || true
   ```
