#!/usr/bin/env bash
# ==============================================================================
# 🚀 AIT Brainlab - CSIM On-Premise NetBird Bootstrap Script
# ==============================================================================
# Purpose:
#   Automatically bootstraps and enrolls any physical or virtual on-premise node
#   (TrueNAS SCALE, Ubuntu Server, or Workstation) located inside the CSIM network
#   into the NetBird WireGuard mesh.
#
# Handled Obstacles:
#   1. Automatic clock synchronization to eliminate TLS/gRPC token clock skew.
#   2. Outbound HTTP/HTTPS proxying through CSIM Squid (192.41.170.82:3128).
#   3. Zero-dependency local CONNECT proxy tunnel for persistent control plane.
#   4. Seamless fallback to NetBird WebSocket Relay over TCP 443.
#
# Usage:
#   sudo ./bootstrap_netbird_csim.sh [--setup-key <KEY>]
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. Configuration & Defaults
# ------------------------------------------------------------------------------
CSIM_PROXY="http://192.41.170.82:3128"
NETBIRD_URL="https://netbird2.brain.cs.ait.ac.th"
NETBIRD_DOMAIN="netbird2.brain.cs.ait.ac.th"
DEFAULT_SETUP_KEY="947F2BE1-B7C6-4709-9A9B-F6680E9D70A9" # TrueNAS setup key

SETUP_KEY="${1:-$DEFAULT_SETUP_KEY}"

echo "=================================================================="
echo "📡 AIT Brainlab - CSIM NetBird Node Bootstrapper"
echo "=================================================================="
echo "Target Management URL: $NETBIRD_URL"
echo "CSIM Forward Proxy:    $CSIM_PROXY"
echo "=================================================================="

# Ensure running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ Error: This script must be run as root (use sudo)." >&2
    exit 1
fi

# ------------------------------------------------------------------------------
# 2. Time Synchronization (Fix Clock Skew)
# ------------------------------------------------------------------------------
echo "🕒 [1/5] Synchronizing system clock..."
timedatectl set-timezone Asia/Bangkok 2>/dev/null || true

# Fetch current date from Google via Squid proxy and set system clock
DATE_HEADER=$(curl -sI -x "$CSIM_PROXY" --connect-timeout 5 http://www.google.com | grep -i '^Date:' | cut -d' ' -f2- || true)
if [ -n "$DATE_HEADER" ]; then
    date -s "$DATE_HEADER" > /dev/null
    hwclock --systohc 2>/dev/null || true
    echo "✔ System clock synchronized to: $(date)"
else
    echo "⚠ Could not fetch date via proxy; using existing clock."
fi

# ------------------------------------------------------------------------------
# 3. Install NetBird Client (if not installed)
# ------------------------------------------------------------------------------
echo "📦 [2/5] Checking NetBird installation..."
if ! command -v netbird &> /dev/null; then
    echo "Downloading and installing NetBird client..."
    export http_proxy="$CSIM_PROXY"
    export https_proxy="$CSIM_PROXY"
    curl -fsSL https://pkgs.netbird.io/install.sh | sh
    unset http_proxy https_proxy
    echo "✔ NetBird client installed successfully."
else
    echo "✔ NetBird client is already installed ($(netbird version 2>/dev/null || which netbird))."
fi

# ------------------------------------------------------------------------------
# 4. Deploy Local Squid Proxy Tunnel
# ------------------------------------------------------------------------------
echo "🔌 [3/5] Deploying local Squid CONNECT proxy tunnel..."
cat << 'EOF' > /usr/local/bin/netbird-proxy-tunnel.py
import socket, threading, sys

PROXY_HOST = "192.41.170.82"
PROXY_PORT = 3128
TARGET_HOST = "netbird2.brain.cs.ait.ac.th"
TARGET_PORT = 443
LOCAL_PORT = 443

def pipe(src, dst):
    try:
        while True:
            data = src.recv(32768)
            if not data: break
            dst.sendall(data)
    except Exception: pass
    finally:
        try: src.close()
        except: pass
        try: dst.close()
        except: pass

def handle(client):
    try:
        p = socket.create_connection((PROXY_HOST, PROXY_PORT), timeout=15)
        p.sendall(f"CONNECT {TARGET_HOST}:{TARGET_PORT} HTTP/1.1\r\nHost: {TARGET_HOST}:{TARGET_PORT}\r\n\r\n".encode())
        resp = p.recv(4096)
        if b"200" not in resp:
            client.close()
            p.close()
            return
        p.settimeout(None)
        client.settimeout(None)
        p.setsockopt(socket.SOL_SOCKET, socket.SO_KEEPALIVE, 1)
        client.setsockopt(socket.SOL_SOCKET, socket.SO_KEEPALIVE, 1)
        threading.Thread(target=pipe, args=(client, p), daemon=True).start()
        threading.Thread(target=pipe, args=(p, client), daemon=True).start()
    except Exception:
        try: client.close()
        except: pass

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(("127.0.0.1", LOCAL_PORT))
s.listen(50)
while True:
    c, _ = s.accept()
    threading.Thread(target=handle, args=(c,), daemon=True).start()
EOF
chmod 755 /usr/local/bin/netbird-proxy-tunnel.py

# Create systemd service for the tunnel
cat << 'EOF' > /etc/systemd/system/netbird-proxy-tunnel.service
[Unit]
Description=NetBird CSIM Squid Proxy Tunnel
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/local/bin/netbird-proxy-tunnel.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now netbird-proxy-tunnel.service
echo "✔ Local proxy tunnel active on 127.0.0.1:443 -> $CSIM_PROXY."

# ------------------------------------------------------------------------------
# 5. Route NetBird Domain to Localhost
# ------------------------------------------------------------------------------
echo "🧭 [4/5] Configuring /etc/hosts routing..."
if ! grep -q "127.0.0.1 $NETBIRD_DOMAIN" /etc/hosts; then
    echo "127.0.0.1 $NETBIRD_DOMAIN" >> /etc/hosts
    echo "✔ Added 127.0.0.1 $NETBIRD_DOMAIN to /etc/hosts."
else
    echo "✔ /etc/hosts already routes $NETBIRD_DOMAIN to loopback."
fi

# ------------------------------------------------------------------------------
# 6. Connect NetBird Mesh
# ------------------------------------------------------------------------------
echo "🚀 [5/5] Connecting to NetBird Mesh..."
systemctl restart netbird
sleep 3

netbird up \
    --management-url "$NETBIRD_URL" \
    --setup-key "$SETUP_KEY"

echo "=================================================================="
echo "🎉 NetBird Node Bootstrap Complete!"
echo "=================================================================="
netbird status
