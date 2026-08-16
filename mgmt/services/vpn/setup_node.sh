#!/usr/bin/env bash
# AIT Brainlab - NetBird Node Setup Script
# Usage: sudo ./setup_node.sh <SETUP_KEY>

set -euo pipefail

SETUP_KEY="${1:-}"

if [[ -z "$SETUP_KEY" ]]; then
  echo "Error: NetBird setup key is required."
  echo "Usage: sudo ./setup_node.sh <SETUP_KEY>"
  exit 1
fi

echo "==> Installing NetBird client..."
if ! command -v netbird &> /dev/null; then
  curl -fsSL https://pkgs.netbird.io/install.sh | sh
fi

echo "==> Connecting to NetBird Managed Cloud..."
netbird down || true
netbird up --management-url https://api.netbird.io --key "$SETUP_KEY"

echo "==> Node Status:"
netbird status
