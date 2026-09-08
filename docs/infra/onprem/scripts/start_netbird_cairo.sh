#!/usr/bin/env bash
# ==============================================================================
# 🚀 AIT Brainlab - TrueNAS SCALE (cairo) NetBird Auto-Connect Script
# ==============================================================================
# Location on NAS: /mnt/pool-1/bin/start-netbird.sh
# Purpose:
#   Runs automatically on boot via TrueNAS "Post Init" script task.
#   Ensures CSIM Squid tunnel, kernel iptables redirection, and NetBird mesh
#   are fully established after ZFS storage pools are mounted.
# ==============================================================================

set -euo pipefail

BIN_DIR="/mnt/pool-1/bin"
NETBIRD_URL="https://netbird.brain.cs.ait.ac.th"
TUNNEL_PORT=33443

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🔄 Starting Cairo NetBird Post-Init connection..."

# 1. Wait for ZFS pool /mnt/pool-1 to be mounted and executable
for i in $(seq 1 30); do
    if [ -x "$BIN_DIR/netbird" ]; then
        break
    fi
    echo "⏳ Waiting for $BIN_DIR to become ready ($i/30)..."
    sleep 1
done

if [ ! -x "$BIN_DIR/netbird" ]; then
    echo "❌ Error: $BIN_DIR/netbird not found or not executable after 30s." >&2
    exit 1
fi

# 2. Restore NetBird config if wiped by TrueNAS appliance reboot/upgrade
PERSIST_DIR="/mnt/pool-1/netbird"
mkdir -p /etc/netbird /var/lib/netbird "$PERSIST_DIR"
if [ ! -f /etc/netbird/config.json ] && [ -f "$PERSIST_DIR/config.json" ]; then
    echo "📦 Restoring NetBird config from $PERSIST_DIR/config.json..."
    cp "$PERSIST_DIR/config.json" /etc/netbird/config.json
    cp "$PERSIST_DIR/config.json" /var/lib/netbird/config.json 2>/dev/null || true
fi

# 3. Re-apply kernel iptables REDIRECT rule (cleared on every reboot)
if [ -f "$BIN_DIR/netbird-iptables.sh" ]; then
    bash "$BIN_DIR/netbird-iptables.sh" start || true
elif [ -f "$BIN_DIR/netbird-iptables" ]; then
    bash "$BIN_DIR/netbird-iptables" start || true
fi
echo "✔ iptables REDIRECT rule verified."

# 3. Ensure CSIM Squid proxy tunnel is active on port 33443
if ! ss -tlpn | grep -q ":${TUNNEL_PORT} "; then
    echo "🔌 Starting CSIM Proxy Tunnel on port ${TUNNEL_PORT}..."
    if systemctl is-active --quiet netbird-proxy-tunnel.service 2>/dev/null; then
        systemctl restart netbird-proxy-tunnel.service || true
    elif systemctl list-unit-files | grep -q netbird-proxy-tunnel.service; then
        systemctl start netbird-proxy-tunnel.service || true
    fi

    # Fallback if systemd unit is missing or failed
    if ! ss -tlpn | grep -q ":${TUNNEL_PORT} "; then
        if [ -f "$BIN_DIR/netbird-proxy-tunnel.py" ]; then
            nohup /usr/bin/python3 "$BIN_DIR/netbird-proxy-tunnel.py" > /var/log/netbird-proxy-tunnel.log 2>&1 &
        elif [ -f "$BIN_DIR/netbird-proxy-tunnel.sh" ]; then
            nohup bash "$BIN_DIR/netbird-proxy-tunnel.sh" > /var/log/netbird-proxy-tunnel.log 2>&1 &
        elif [ -f "$BIN_DIR/netbird-proxy-tunnel" ]; then
            nohup "$BIN_DIR/netbird-proxy-tunnel" > /var/log/netbird-proxy-tunnel.log 2>&1 &
        fi
        sleep 2
    fi
fi
echo "✔ Proxy tunnel verified on port ${TUNNEL_PORT}."

# 4. Start / Restart NetBird daemon service
if systemctl list-unit-files | grep -q netbird.service; then
    systemctl restart netbird || true
    sleep 2
fi

# 5. Connect NetBird client to mesh
echo "📡 Connecting NetBird client to $NETBIRD_URL..."
"$BIN_DIR/netbird" up --management-url "$NETBIRD_URL" 2>/dev/null || true

# 6. Verify connection status
echo "📊 NetBird status:"
"$BIN_DIR/netbird" status || true

# 7. Keep backup copy updated on ZFS pool
if [ -f /etc/netbird/config.json ]; then
    cp /etc/netbird/config.json "$PERSIST_DIR/config.json"
elif [ -f /var/lib/netbird/config.json ]; then
    cp /var/lib/netbird/config.json "$PERSIST_DIR/config.json"
fi

# 8. Refresh TrueNAS Directory Services (rebind LDAP over mesh)
if command -v midclt &>/dev/null; then
    echo "🔄 Refreshing TrueNAS LDAP Directory Services..."
    midclt call service.restart "ldap" >/dev/null 2>&1 || true
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🎉 Cairo NetBird auto-connect finished successfully."
