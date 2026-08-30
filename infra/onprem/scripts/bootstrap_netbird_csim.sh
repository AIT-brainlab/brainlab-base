#!/usr/bin/env bash
# ==============================================================================
# 🚀 AIT Brainlab - CSIM On-Premise NetBird Bootstrap Script (Standardized)
# ==============================================================================
# Purpose:
#   Bootstraps and enrolls any on-premise node (TrueNAS SCALE, Ubuntu Server,
#   GPU Compute, Workstations) located inside the CSIM network into the NetBird
#   WireGuard mesh.
#
# Design Principles:
#   1. TrueNAS Appliance Aware: Stores binaries and scripts in writable persistent
#      locations (/mnt/pool-1/bin or /var/lib/netbird/bin), bypassing root read-only locks.
#   2. Zero Manual Config: Automatically injects self-hosted ManagementURL into
#      /var/lib/netbird/default.json and /etc/netbird/config.json (never touches api.netbird.io).
#   3. Dynamic Cloud IP: Resolves netbird2.brain.cs.ait.ac.th dynamically on every
#      run (resilient to GCP VM destructions & IP refreshes).
#   4. Non-Intrusive: Runs local Squid tunnel on high-port 33443 (leaves port 443
#      100% free for TrueNAS Web GUI, JupyterHub, Nginx, or Traefik).
#   5. Kernel Redirection: Uses a single native Linux iptables REDIRECT rule for
#      outbound packets to the live Cloud IP (CLOUD_MGMT_IP:443 -> 33443).
#   6. Zero /etc/hosts Tampering: Does not modify /etc/hosts.
#
# Usage:
#   sudo ./bootstrap_netbird_csim.sh [<SETUP_KEY>]
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. Configuration & Defaults
# ------------------------------------------------------------------------------
CSIM_PROXY="http://192.41.170.82:3128"
NETBIRD_URL="https://netbird.brain.cs.ait.ac.th"
NETBIRD_DOMAIN="netbird.brain.cs.ait.ac.th"
TUNNEL_PORT=33443
DEFAULT_SETUP_KEY="6BAC3****" # TrueNAS setup key

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

# Detect appliance type and select writable binary directory
IS_TRUENAS=false
if grep -qi "truenas" /etc/os-release 2>/dev/null || command -v midclt &>/dev/null; then
    IS_TRUENAS=true
fi

if [ "$IS_TRUENAS" = true ]; then
    if [ -d "/mnt/pool-1" ]; then
        BIN_DIR="/mnt/pool-1/bin"
    else
        BIN_DIR="/var/lib/netbird/bin"
    fi
else
    BIN_DIR="/usr/local/bin"
fi
mkdir -p "$BIN_DIR" /etc/netbird /var/lib/netbird
echo "✔ Target binary path: $BIN_DIR"

# ------------------------------------------------------------------------------
# 2. Time Synchronization (Eliminate Clock Skew)
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
# 3. Dynamic DNS Resolution of Cloud Management IP
# ------------------------------------------------------------------------------
echo "🔍 [2/6] Resolving live Cloud Management IP..."
CLOUD_MGMT_IP=$(python3 -c "import socket; print(socket.gethostbyname('$NETBIRD_DOMAIN'))" 2>/dev/null || true)

if [ -z "$CLOUD_MGMT_IP" ]; then
    CLOUD_MGMT_IP=$(nslookup "$NETBIRD_DOMAIN" 2>/dev/null | awk '/^Address: / { print $2 }' | tail -n 1 || true)
fi

if [ -z "$CLOUD_MGMT_IP" ]; then
    echo "❌ Error: Could not resolve $NETBIRD_DOMAIN via DNS." >&2
    exit 1
fi
echo "✔ Discovered live Cloud Management IP: $CLOUD_MGMT_IP"

# ------------------------------------------------------------------------------
# 4. Install NetBird Client & Auto-Inject Self-Hosted Configuration
# ------------------------------------------------------------------------------
echo "📦 [3/6] Installing NetBird & injecting self-hosted configuration..."
NETBIRD_BIN="$BIN_DIR/netbird"

if [ ! -f "$NETBIRD_BIN" ] && ! command -v netbird &> /dev/null; then
    if [ "$IS_TRUENAS" = true ]; then
        echo "TrueNAS appliance detected. Installing standalone binary into $BIN_DIR..."
        TMP_DIR=$(mktemp -d)
        curl -x "$CSIM_PROXY" -fsSL "https://github.com/netbirdio/netbird/releases/download/v0.77.1/netbird_0.77.1_linux_amd64.tar.gz" -o "$TMP_DIR/netbird.tar.gz"
        tar -xzf "$TMP_DIR/netbird.tar.gz" -C "$BIN_DIR" netbird
        chmod 755 "$NETBIRD_BIN"
        rm -rf "$TMP_DIR"

        # Register systemd unit pointing directly to our persistent binary
        "$NETBIRD_BIN" service install 2>/dev/null || true
    else
        echo "Downloading and installing NetBird client via official package..."
        export http_proxy="$CSIM_PROXY"
        export https_proxy="$CSIM_PROXY"
        curl -fsSL https://pkgs.netbird.io/install.sh | sh
        unset http_proxy https_proxy
        NETBIRD_BIN=$(command -v netbird)
    fi
    echo "✔ NetBird client installed at $NETBIRD_BIN."
else
    if [ -f "$NETBIRD_BIN" ]; then
        echo "✔ NetBird client exists at $NETBIRD_BIN."
    else
        NETBIRD_BIN=$(command -v netbird)
        echo "✔ NetBird client exists at $NETBIRD_BIN."
    fi
fi

# Ensure netbird systemd service unit exists
if [ ! -f /etc/systemd/system/netbird.service ]; then
    "$NETBIRD_BIN" service install 2>/dev/null || true
fi

# Ensure directories exist
mkdir -p /var/log/netbird /var/lib/netbird /etc/netbird

# Stop daemon temporarily to inject clean CLI arguments into service unit
systemctl stop netbird 2>/dev/null || true

# Clean any broken synthetic JSON files that cause Go struct unmarshal errors
if [ -f /var/lib/netbird/default.json ] && ! grep -q "WireGuardKeyPair" /var/lib/netbird/default.json 2>/dev/null; then
    rm -f /var/lib/netbird/default.json /etc/netbird/config.json 2>/dev/null || true
fi

# Inject --management-url directly into systemd ExecStart so Go parses it natively
if [ -f /etc/systemd/system/netbird.service ]; then
    if ! grep -q -- "--management-url" /etc/systemd/system/netbird.service; then
        sed -i "s|\"service\" \"run\"|\"service\" \"run\" \"--management-url\" \"$NETBIRD_URL\"|g" /etc/systemd/system/netbird.service
    fi
fi
echo "✔ Configured NetBird systemd service with native --management-url flag."

# ------------------------------------------------------------------------------
# 5. Deploy Local Squid Proxy Tunnel (on port 33443)
# ------------------------------------------------------------------------------
echo "🔌 [4/6] Deploying local Squid CONNECT proxy tunnel on port $TUNNEL_PORT..."
TUNNEL_SCRIPT="$BIN_DIR/netbird-proxy-tunnel.py"

cat << EOF > "$TUNNEL_SCRIPT"
import socket, threading, sys

PROXY_HOST = "192.41.170.82"
PROXY_PORT = 3128
TARGET_HOST = "netbird.brain.cs.ait.ac.th"
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
chmod 755 "$TUNNEL_SCRIPT"

# Deploy dedicated iptables boot helper script
IPTABLES_HELPER="$BIN_DIR/netbird-iptables.sh"
cat << 'EOF' > "$IPTABLES_HELPER"
#!/bin/sh
NETBIRD_DOMAIN="netbird.brain.cs.ait.ac.th"
TUNNEL_PORT=33443

ACTION="${1:-start}"
CLOUD_IP=$(python3 -c "import socket; print(socket.gethostbyname('$NETBIRD_DOMAIN'))" 2>/dev/null || \
          nslookup "$NETBIRD_DOMAIN" 2>/dev/null | awk '/^Address: / { print $2 }' | tail -n 1)

if [ -z "$CLOUD_IP" ]; then
    echo "⚠ netbird-iptables: Could not resolve $NETBIRD_DOMAIN via DNS" >&2
    exit 0
fi

if [ "$ACTION" = "stop" ]; then
    iptables -t nat -D OUTPUT -p tcp -d "$CLOUD_IP" --dport 443 -j REDIRECT --to-ports "$TUNNEL_PORT" 2>/dev/null || true
else
    iptables -t nat -C OUTPUT -p tcp -d "$CLOUD_IP" --dport 443 -j REDIRECT --to-ports "$TUNNEL_PORT" 2>/dev/null || \
    iptables -t nat -A OUTPUT -p tcp -d "$CLOUD_IP" --dport 443 -j REDIRECT --to-ports "$TUNNEL_PORT"
fi
EOF
chmod 755 "$IPTABLES_HELPER"

# Immediately apply the iptables rule
"$IPTABLES_HELPER" start

# Create and enable systemd service for proxy tunnel with automatic iptables persistence
cat << EOF > /etc/systemd/system/netbird-proxy-tunnel.service
[Unit]
Description=NetBird CSIM Squid Proxy Tunnel
After=network.target

[Service]
Type=simple
ExecStartPre=-$IPTABLES_HELPER start
ExecStart=/usr/bin/python3 $TUNNEL_SCRIPT
ExecStopPost=-$IPTABLES_HELPER stop
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Ensure custom binary directory is in global shell PATH
if [ "$BIN_DIR" != "/usr/local/bin" ]; then
    echo "export PATH=\"$BIN_DIR:\$PATH\"" > /etc/profile.d/netbird.sh
    chmod 644 /etc/profile.d/netbird.sh
fi

systemctl daemon-reload
systemctl enable --now netbird-proxy-tunnel.service
echo "✔ Proxy tunnel active on 127.0.0.1:$TUNNEL_PORT (with automatic boot iptables redirect)."

# ------------------------------------------------------------------------------
# 7. Connect to NetBird Mesh
# ------------------------------------------------------------------------------
echo "🚀 [6/6] Connecting to NetBird Mesh..."
systemctl daemon-reload
systemctl enable --now netbird
sleep 2

"$NETBIRD_BIN" up \
    --management-url "$NETBIRD_URL" \
    --setup-key "$SETUP_KEY"

echo "=================================================================="
echo "🎉 NetBird Node Bootstrap Complete!"
echo "=================================================================="
"$NETBIRD_BIN" status

# Automatically refresh Directory Services (TrueNAS midclt or Ubuntu SSSD)
if command -v midclt &>/dev/null; then
    echo "🔄 Refreshing TrueNAS Directory Services..."
    midclt call service.restart "ldap" >/dev/null 2>&1 || true
    echo "✔ TrueNAS Directory Services refreshed."
elif command -v sssd &>/dev/null || systemctl is-active --quiet sssd 2>/dev/null; then
    echo "🔄 Refreshing SSSD Directory Services cache..."
    command -v sss_cache &>/dev/null && sss_cache -E 2>/dev/null || true
    systemctl restart sssd 2>/dev/null || true
    echo "✔ SSSD Directory Services refreshed."
fi
