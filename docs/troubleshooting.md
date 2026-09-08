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

---

## 9. Issue: Proxmox Tenant VMs (SDN) Lose Internet Egress & NetBird Disconnects
### Symptoms:
- Tenant VMs on Proxmox SDN (`10.10.250.x` such as `brainlab-services` or `dlms-server`) cannot reach external hosts or the CSIM proxy (`192.41.170.82`).
- NetBird fails with:
  `Management: Disconnected, reason: rpc error: code = FailedPrecondition desc = failed connecting to Management Service : create connection: dial context: context deadline exceeded`

### Root Causes:
1. **Missing Proxmox SDN SNAT / Masquerade**: After a Proxmox reboot or SDN change, the kernel `iptables` NAT table on the hypervisor host (`192.41.170.19`) is missing the `POSTROUTING -s 10.10.0.0/16 -j MASQUERADE` rule. Packets leave Proxmox with raw `10.10.250.x` source IPs, and replies from external LAN devices cannot route back.
2. **Stale / Inactive Proxy Tunnel**: On the VM, `netbird-proxy-tunnel.service` stopped or its iptables redirect rule was dropped.

### Resolution:
1. **Fix Proxmox Host (`192.41.170.19`) Routing & NAT**:
   ```bash
   # Enable IP forwarding
   sysctl -w net.ipv4.ip_forward=1

   # Add MASQUERADE for the 10.10.0.0/16 SDN subnet
   iptables -t nat -C POSTROUTING -s 10.10.0.0/16 -j MASQUERADE 2>/dev/null || \
     iptables -t nat -A POSTROUTING -s 10.10.0.0/16 -j MASQUERADE

   # Allow forwarding
   iptables -C FORWARD -s 10.10.0.0/16 -j ACCEPT 2>/dev/null || \
     iptables -I FORWARD 1 -s 10.10.0.0/16 -j ACCEPT
   iptables -C FORWARD -d 10.10.0.0/16 -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || \
     iptables -I FORWARD 2 -d 10.10.0.0/16 -m state --state RELATED,ESTABLISHED -j ACCEPT
   ```
2. **Restart Proxy Tunnel & NetBird on the Tenant VM**:
   ```bash
   sudo systemctl restart netbird-proxy-tunnel.service
   sudo systemctl restart netbird.service
   netbird status
   ```
3. **Make the Proxmox NAT Rule Permanent (Across Host Reboots)**:
   On the Proxmox host (`192.41.170.19`), save rules using `iptables-persistent`:
   ```bash
   apt-get install -y iptables-persistent
   netfilter-persistent save
   ```
   Or add to `/etc/network/interfaces` under the SDN or primary bridge:
   ```text
   post-up iptables -t nat -C POSTROUTING -s 10.10.0.0/16 -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -s 10.10.0.0/16 -j MASQUERADE
   post-up iptables -C FORWARD -s 10.10.0.0/16 -j ACCEPT 2>/dev/null || iptables -I FORWARD 1 -s 10.10.0.0/16 -j ACCEPT
   ```

---

## 10. Issue: TrueNAS SCALE (`cairo`) Loses NetBird After Reboot
### Symptoms:
- Following a reboot or TrueNAS SCALE system upgrade, `cairo` drops off the NetBird mesh.
- Running `ls -la /etc/netbird/config.json` reveals the configuration is missing or empty.
- NetBird systemd unit failed during boot with `status=203/EXEC` or `No such file or directory`.

### Root Causes:
1. **ZFS Storage Pool Timing**: `/mnt/pool-1` is imported and mounted late in the boot sequence by TrueNAS middleware (`middlewared`). Standard systemd services trying to run `/mnt/pool-1/bin/netbird` fail during early boot before the pool is mounted.
2. **Volatile Kernel `iptables`**: Outbound traffic to `netbird.brain.cs.ait.ac.th:443` requires redirection to the local CSIM proxy tunnel (`33443`). Kernel iptables rules in RAM are cleared on reboot.
3. **Appliance Model**: TrueNAS SCALE updates replace the boot environment, wiping changes in `/etc/netbird`.

### Resolution:
1. **Restore / Reconnect Immediately**:
   ```bash
   # Re-apply kernel iptables redirect
   sudo bash /mnt/pool-1/bin/netbird-iptables.sh start 2>/dev/null || sudo bash /mnt/pool-1/bin/netbird-iptables start

   # Restart proxy tunnel & NetBird daemon
   sudo systemctl restart netbird-proxy-tunnel.service 2>/dev/null || \
     sudo nohup python3 /mnt/pool-1/bin/netbird-proxy-tunnel.py > /var/log/netbird-proxy-tunnel.log 2>&1 &
   sudo systemctl restart netbird 2>/dev/null || true

   # Bring NetBird up
   sudo /mnt/pool-1/bin/netbird up --management-url https://netbird.brain.cs.ait.ac.th
   ```
2. **Persist Identity on ZFS Pool**:
   ```bash
   sudo mkdir -p /mnt/pool-1/netbird
   sudo cp /etc/netbird/config.json /mnt/pool-1/netbird/config.json
   ```
3. **Configure TrueNAS Post-Init Task**:
   Ensure `/mnt/pool-1/bin/start-netbird.sh` (tracked in `docs/infra/onprem/scripts/start_netbird_cairo.sh`) is registered in TrueNAS middleware so it runs automatically on every boot:
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


