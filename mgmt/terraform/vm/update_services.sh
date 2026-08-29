#!/usr/bin/env bash
# ==========================================================
# ⚡ 1-Click Fast In-Place Container Updater
# ==========================================================
# Pulls latest image layers and restarts containers in ~5s
# without rebooting the VM or causing DNS downtime.
# ==========================================================
set -euo pipefail

PROJECT="${1:-ait-brainlab-mgmt}"
ZONE="${2:-asia-southeast1-a}"
VM_NAME="${3:-brainlab-mgmt-vm}"

echo "=========================================================="
echo "🚀 Triggering Fast In-Place Container Update on ${VM_NAME}..."
echo "=========================================================="

gcloud compute ssh "${VM_NAME}" \
  --project="${PROJECT}" \
  --zone="${ZONE}" \
  --tunnel-through-iap \
  --command="
    cd /opt/brainlab
    echo '==> 📥 Pulling updated Docker images...'
    sudo docker compose pull
    echo '==> 🔄 Restarting updated services...'
    sudo docker compose up -d --remove-orphans
    echo '==> 🐳 Running Containers:'
    sudo docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
  "

echo "=========================================================="
echo "✅ Update complete in seconds!"
echo "=========================================================="
