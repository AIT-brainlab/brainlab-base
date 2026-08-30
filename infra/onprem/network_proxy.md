# CSIM Network, Proxy & Time Synchronization

## Overview
Due to CSIM institutional firewall rules, outbound HTTP/HTTPS internet access requires routing through the CSIM HTTP proxy.

---

## 1. NTP Server & Timezone Configuration

The official CSIM NTP domain is `ntp.cs.ait.ac.th`.

### Step 1: Set Timezone
```bash
sudo timedatectl set-timezone Asia/Bangkok
```

### Step 2: Configure `/etc/systemd/timesyncd.conf`
Add the following configuration:
```ini
[Time]
NTP=ntp.cs.ait.ac.th
FallbackNTP=ntp.ubuntu.com
RootDistanceMaxSec=5
PollIntervalMinSec=32
PollIntervalMaxSec=2048
```

### Step 3: Restart & Verify
```bash
sudo systemctl restart systemd-timesyncd.service
timedatectl
```

---

## 2. Institutional Proxy Setup (`192.41.170.82:3128`)

### Step 1: User Environment (`~/.bashrc` & `/etc/environment`)
Add proxy exports to `/etc/environment` or user `~/.bashrc`:
```bash
export http_proxy=http://192.41.170.82:3128
export https_proxy=http://192.41.170.82:3128
export ftp_proxy=http://192.41.170.82:3128
export no_proxy="localhost,127.0.0.1,192.41.170.0/24,100.74.0.0/16,*.ait.ac.th,*.ait.asia,*.brain.cs.ait.ac.th"
```

### Step 2: APT Package Manager Proxy
Create `/etc/apt/apt.conf.d/proxy.conf`:
```text
Acquire::http::Proxy "http://192.41.170.82:3128/";
Acquire::https::Proxy "http://192.41.170.82:3128/";
```

### Step 3: Sudoers Environment Preservation
Preserve proxy variables when executing `sudo`:
```bash
sudo visudo
```
Add this line:
```text
Defaults env_keep += "ftp_proxy http_proxy https_proxy no_proxy"
```
