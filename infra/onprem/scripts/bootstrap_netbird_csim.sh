#!/usr/bin/env bash
# ==============================================================================
# 🚀 AIT Brainlab - CSIM On-Premise NetBird Bootstrap & Auto-Recovery Script
# ==============================================================================
# Purpose:
#   Automatically bootstraps, enrolls, and permanently maintains any physical or
#   virtual on-premise node (TrueNAS SCALE, Ubuntu Server, GPU Compute, Workstation)
#   located inside the CSIM network into the NetBird WireGuard mesh.
#
# Handled Obstacles & Features:
#   1. Automatic clock synchronization via Squid to eliminate TLS/gRPC token skew.
#   2. Pre-seeds /etc/netbird/config.json with self-hosted URL (never dials api.netbird.io).
#   3. Smart port detection:
#      - If port 443 is free (TrueNAS): uses 127.0.0.1:443 + /etc/hosts.
#      - If port 443 is busy (JupyterHub on 'la'): uses port 33443 + iptables REDIRECT.
#   4. TrueNAS SCALE OS Upgrade Persistence:
#      - If TrueNAS (/mnt/pool-1) is detected, saves copy to persistent ZFS storage
#      - Registers Post-Init script in TrueNAS SQLite database so NetBird automatically
#        restores after every future TrueNAS OS upgrade.
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
CLOUD_MGMT_IP="136.85.52.234"
DEFAULT_SETUP_KEY="947F2BE1-B7C6-4709-9A9B-F6680E9D70A9" # TrueNAS setup key

SETUP_KEY="${1:-$DEFAULT_SETUP_KEY}"

echo "=================================================================="
echo "📡 AIT Brainlab - CSIM NetBird Node Bootstrapper (v2.0)"
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
echo "🕒 [1/6] Synchronizing system clock..."
timedatectl set-timezone Asia/Bangkok 2>/dev/null || true

DATE_HEADER=$(curl -sI -x "$CSIM_PROXY" --connect-timeout 5 http://www.google.com | grep -i '^Date:' | cut -d' ' -f2- || true)
if [ -n "$DATE_HEADER" ]; then
    date -s "$DATE_HEADER" > /dev/null
    hwclock --systohc 2>/dev/null || true
    echo "✔ System clock synchronized: $(date)"
else
    echo "⚠ Could not fetch date via proxy; using existing clock."
fi

# ------------------------------------------------------------------------------
# 3. Install NetBird Client & Pre-seed Self-Hosted Configuration
# ------------------------------------------------------------------------------
echo "📦 [2/6] Checking NetBird installation & pre-seeding configuration..."
if ! command -v netbird &> /dev/null; then
    echo "Downloading and installing NetBird client..."
    export http_proxy="$CSIM_PROXY"
    export https_proxy="$CSIM_PROXY"
    curl -fsSL https://pkgs.netbird.io/install.sh | sh
    unset http_proxy https_proxy
    echo "✔ NetBird client installed successfully."
else
    echo "✔ NetBird client is already installed."
fi

# Pre-seed config.json with our self-hosted URL so it never connects to api.netbird.io
mkdir -p /etc/netbird
if [ ! -f /etc/netbird/config.json ] || grep -q "api.netbird.io" /etc/netbird/config.json; then
    cat << EOF > /etc/netbird/config.json
{
  "ManagementURL": "$NETBIRD_URL",
  "AdminURL": "$NETBIRD_URL"
}
EOF
    echo "✔ Pre-seeded /etc/netbird/config.json with $NETBIRD_URL."
fi

# ------------------------------------------------------------------------------
# 4. Smart Port Detection & Proxy Tunnel Deployment
# ------------------------------------------------------------------------------
echo "🔌 [3/6] Configuring local Squid CONNECT proxy tunnel..."

# Check if port 443 is already occupied (e.g. JupyterHub on compute servers)
PORT_443_OCCUPIED=false
if ss -tulpn 2>/dev/null | grep -E ":443\s" | grep -qv "netbird-proxy-tunnel"; then
    PORT_443_OCCUPIED=true
fi

if [ "$PORT_443_OCCUPIED" = true ]; then
    TUNNEL_PORT=33443
    echo "ℹ️ Port 443 is in use locally (e.g. JupyterHub). Using high-port 33443 with iptables REDIRECT."
else
    TUNNEL_PORT=443
    echo "ℹ️ Port 443 is free. Using direct loopback port 443."
fi

# Deploy Python CONNECT Tunnel Script
cat << EOF > /usr/local/bin/netbird-proxy-tunnel.py
import socket, threading, sys

PROXY_HOST = "192.41.170.82"
PROXY_PORT = 3128
TARGET_HOST = "netbird2.brain.cs.ait.ac.th"
TARGET_PORT = 443
LOCAL_PORT = $TUNNEL_PORT

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

# Create and enable systemd service
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
echo "✔ Proxy tunnel active on 127.0.0.1:$TUNNEL_PORT -> $CSIM_PROXY."

# ------------------------------------------------------------------------------
# 5. Routing Strategy (iptables REDIRECT vs. /etc/hosts)
# ------------------------------------------------------------------------------
echo "🧭 [4/6] Configuring network routing..."
if [ "$PORT_443_OCCUPIED" = true ]; then
    # High-port mode: ensure /etc/hosts does NOT redirect domain to 127.0.0.1
    sed -i "/$NETBIRD_DOMAIN/d" /etc/hosts 2>/dev/null || true
    # Add kernel iptables REDIRECT rule for outbound Cloud Management IP
    iptables -t nat -C OUTPUT -p tcp -d "$CLOUD_MGMT_IP" --dport 443 -j REDIRECT --to-ports "$TUNNEL_PORT" 2>/dev/null || \
    iptables -t nat -A OUTPUT -p tcp -d "$CLOUD_MGMT_IP" --dport 443 -j REDIRECT --to-ports "$TUNNEL_PORT"
    echo "✔ Configured iptables REDIRECT: $CLOUD_MGMT_IP:443 -> 127.0.0.1:$TUNNEL_PORT."
else
    # Port 443 free mode: route domain to loopback in /etc/hosts
    if ! grep -q "127.0.0.1 $NETBIRD_DOMAIN" /etc/hosts; then
        echo "127.0.0.1 $NETBIRD_DOMAIN" >> /etc/hosts
        echo "✔ Added 127.0.0.1 $NETBIRD_DOMAIN to /etc/hosts."
    fi
fi

# ------------------------------------------------------------------------------
# 6. TrueNAS SCALE Upgrade Persistence (Post-Init Script Registration)
# ------------------------------------------------------------------------------
echo "💾 [5/6] Checking storage persistence..."
if [ -d "/mnt/pool-1" ] && command -v midclt &> /dev/null; then
    mkdir -p /mnt/pool-1/scripts
    cp -f "$0" /mnt/pool-1/scripts/bootstrap_netbird_csim.sh 2>/dev/null || true
    chmod +x /mnt/pool-1/scripts/bootstrap_netbird_csim.sh 2>/dev/null || true

    # Register Post-Init script in TrueNAS database if not present
    REGISTERED=$(midclt call initshutdownscript.query '[["command", "=", "/mnt/pool-1/scripts/bootstrap_netbird_csim.sh"]]' 2>/dev/null || true)
    if [ -z "$REGISTERED" ] || [ "$REGISTERED" = "[]" ]; then
        midclt call initshutdownscript.create '{"type": "SCRIPT", "command": "/mnt/pool-1/scripts/bootstrap_netbird_csim.sh", "when": "POSTINIT", "enabled": true, "timeout": 60}' >/dev/null 2>&1 || true
        echo "✔ Registered Post-Init script in TrueNAS database for zero-touch upgrade persistence!"
    else
        echo "✔ TrueNAS Post-Init upgrade persistence already registered."
    fi
fi

# ------------------------------------------------------------------------------
# 7. Connect NetBird Mesh
# ------------------------------------------------------------------------------
echo "🚀 [6/6] Connecting to NetBird Mesh..."
systemctl restart netbird
sleep 3

netbird up \
    --management-url "$NETBIRD_URL" \
    --setup-key "$SETUP_KEY"

echo "=================================================================="
echo "🎉 NetBird Node Bootstrap Complete!"
echo "=================================================================="
netbird status
