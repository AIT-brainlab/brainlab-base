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
- `ls /mnt/HDD/home` hangs indefinitely or returns `Stale file handle`.

### Resolution:
1. Force unmount the stale mount:
   ```bash
   sudo umount -l /mnt/HDD/home
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
   curl -I --proxy http://192.41.170.23:3128 https://www.google.com
   ```
2. Ensure proxy environment variables are exported in current subshell:
   ```bash
   export http_proxy=http://192.41.170.23:3128
   export https_proxy=http://192.41.170.23:3128
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
   ls -ld /mnt/HDD/home/<username>/work
   ```
3. Manually remove stuck container if present:
   ```bash
   docker rm -f jupyter-<username>
   ```
