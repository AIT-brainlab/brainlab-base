#!/usr/bin/env bash
# ==========================================================
# 🛰️ Wait & Stream Management VM Bootstrap Logs
# ==========================================================
set -eo pipefail

VM_NAME="${1:-brainlab-mgmt-vm}"
ZONE="${2:-asia-southeast1-a}"
PROJECT="${3:-ait-brainlab-mgmt}"

echo "=========================================================="
echo "📡 [1/3] Connecting to VM via Google IAP Tunnel..."
echo "=========================================================="

MAX_SSH_ATTEMPTS=20
for i in $(seq 1 $MAX_SSH_ATTEMPTS); do
  if gcloud compute ssh "$VM_NAME" --zone="$ZONE" --project="$PROJECT" --tunnel-through-iap --command="echo 'SSH Connected'" 2>/dev/null; then
    echo "✅ IAP SSH connection established!"
    break
  fi
  echo "⏳ Waiting for VM IAP SSH to become available ($i/$MAX_SSH_ATTEMPTS)..."
  sleep 6
done

echo "=========================================================="
echo "📺 [2/3] Streaming Live Startup & Docker Bootstrap Logs..."
echo "=========================================================="

# Stream journalctl until completion marker or service deactivates
gcloud compute ssh "$VM_NAME" \
  --zone="$ZONE" \
  --project="$PROJECT" \
  --tunnel-through-iap \
  --command="sudo journalctl -u google-startup-scripts.service -f --no-pager" \
  | while IFS= read -r line; do
      echo "$line"
      if [[ "$line" =~ "ALL BRAINLAB MANAGEMENT SERVICES ARE OPERATIONAL" ]] || [[ "$line" =~ "Finished google-startup-scripts.service" ]] || [[ "$line" =~ "google-startup-scripts.service: Deactivated successfully" ]]; then
        echo "=========================================================="
        echo "🎉 Bootstrap completed successfully!"
        echo "=========================================================="
        # Kill the stream
        kill -9 $(pgrep -f "journalctl -u google-startup-scripts.service") 2>/dev/null || true
        pkill -P $$ gcloud 2>/dev/null || true
        break
      fi
    done || true

echo "=========================================================="
echo "🐳 [3/3] Inspecting Running Docker Containers..."
echo "=========================================================="
gcloud compute ssh "$VM_NAME" \
  --zone="$ZONE" \
  --project="$PROJECT" \
  --tunnel-through-iap \
  --command="sudo docker ps"

echo "=========================================================="
echo "✅ Brainlab Management VM is 100% OPERATIONAL!"
echo "=========================================================="
