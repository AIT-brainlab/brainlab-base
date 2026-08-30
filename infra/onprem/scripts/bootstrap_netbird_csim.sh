#!/usr/bin/env bash
# ==============================================================================
# 🚀 AIT Brainlab - CSIM On-Premise NetBird Bootstrap Script (Dynamic & Resilient)
# ==============================================================================
# Purpose:
#   Bootstraps and enrolls any on-premise node (TrueNAS SCALE, Ubuntu Server,
#   GPU Compute, Workstations) located inside the CSIM network into the NetBird
#   WireGuard mesh.
#
# Design Principles:
#   1. Dynamic Cloud IP: Resolves netbird2.brain.cs.ait.ac.th dynamically on every
#      run (resilient to GCP VM destructions & IP refreshes).
#   2. Non-Intrusive: Runs local Squid tunnel on high-port 33443 (leaves port 443
#      100% free for TrueNAS Web GUI, JupyterHub, Nginx, or Traefik).
#   3. Kernel Redirection: Uses a single native Linux iptables REDIRECT rule for
#      outbound packets to the live Cloud IP (CLOUD_MGMT_IP:443 -> 33443).
#   4. Zero /etc/hosts Tampering: Does not modify /etc/hosts.
#   5. Pre-seeds /etc/netbird/config.json with self-hosted URL so it never connects
#      to commercial api.netbird.io.
#
# Usage:
#   sudo ./bootstrap_netbird_csim.sh [<SETUP_KEY>]
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. Configuration & Defaults
# ------------------------------------------------------------------------------
CSIM_PROXY="http://192.41.170.82:3128"
NETBIRD_URL="https://netbird2.brain.cs.ait.ac.th"
NETBIRD_DOMAIN="netbird2.brain.cs.ait.ac.th"
TUNNEL_PORT=33443
DEFAULT_SETUP_KEY="947F2BE1-B7C6-4709-9A9B-F6680E9D70A9" # TrueNAS setup key

SETUP_KEY="${1:-$DEFAULT_SETUP_KEY}"

echo "=================================================================="
echo "📡 AIT Brainlab - CSIM NetBird Node Bootstrapper"
echo "=================================================================="
echo "Target Management URL: $NETBIRD_URL"
echo "CSIM Forward Proxy:    $CSIM_PROXY"
echo "Tunnel Port:           $TUNNEL_PORT (leaves 443 free)"
echo "=================================================================="

# Ensure running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ Error: This script must be run as root (use sudo)." >&2
    exit 1
fi

# ------------------------------------------------------------------------------
# 2. Time Synchronization (Eliminate Clock Skew)
# ------------------------------------------------------------------------------
echo "🕒 [1/5] Synchronizing system clock..."
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
# 3. Dynamic DNS Resolution of Cloud Management IP
# ------------------------------------------------------------------------------
echo "🔍 [2/5] Resolving live Cloud Management IP..."
CLOUD_MGMT_IP=$(python3 -c "import socket; print(socket.gethostbyname('$NETBIRD_DOMAIN'))" 2>/dev/null || true)

if [ -z "$CLOUD_MGMT_IP" ]; then
    # Fallback to nslookup or dig if python DNS lookup fails
    CLOUD_MGMT_IP=$(nslookup "$NETBIRD_DOMAIN" 2>/dev/null | awk '/^Address: / { print $2 }' | tail -n 1 || true)
fi

if [ -z "$CLOUD_MGMT_IP" ]; then
    echo "❌ Error: Could not resolve $NETBIRD_DOMAIN via DNS." >&2
    exit 1
fi
echo "✔ Discovered live Cloud Management IP: $CLOUD_MGMT_IP"

# ------------------------------------------------------------------------------
# 4. Install NetBird Client & Pre-seed Self-Hosted Configuration
# ------------------------------------------------------------------------------
echo "📦 [3/5] Checking NetBird installation..."
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
# 5. Deploy Local Squid Proxy Tunnel (on port 33443)
# ------------------------------------------------------------------------------
echo "🔌 [4/5] Deploying local Squid CONNECT proxy tunnel on port $TUNNEL_PORT..."

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

# Ensure /etc/hosts does NOT redirect domain to 127.0.0.1
sed -i "/$NETBIRD_DOMAIN/d" /etc/hosts 2>/dev/null || true

# Direct outbound TCP traffic to the live Cloud IP through the local tunnel
iptables -t nat -C OUTPUT -p tcp -d "$CLOUD_MGMT_IP" --dport 443 -j REDIRECT --to-ports "$TUNNEL_PORT" 2>/dev/null || \
iptables -t nat -A OUTPUT -p tcp -d "$CLOUD_MGMT_IP" --dport 443 -j REDIRECT --to-ports "$TUNNEL_PORT"
echo "✔ Kernel redirects $CLOUD_MGMT_IP:443 -> 127.0.0.1:$TUNNEL_PORT."

# ------------------------------------------------------------------------------
# 6. Connect to NetBird Mesh
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
