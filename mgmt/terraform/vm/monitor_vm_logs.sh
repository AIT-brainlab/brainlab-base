#!/usr/bin/env bash
# ==========================================================
# 📺 Brainlab Management VM Log Monitor & Bootstrap Inspector
# ==========================================================
set -e

GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
NC="\033[0m" # No Color

VM_NAME="brainlab-mgmt-vm"
ZONE="asia-southeast1-a"
PROJECT="ait-brainlab-mgmt"

MODE="${1:-1}"

show_menu() {
  echo "=========================================================="
  echo -e "${BLUE}📺 Brainlab Management VM Log Monitor (${VM_NAME})${NC}"
  echo "=========================================================="
  echo -e "  ${GREEN}1)${NC} Live Startup & Bootstrap Logs   (google-startup-scripts.service)"
  echo -e "  ${CYAN}2)${NC} Live Docker Container Logs      (Traefik, LLDAP, NetBird)"
  echo -e "  ${YELLOW}3)${NC} Live GCE Serial Console Logs    (Kernel / Hardware Boot)"
  echo -e "  ${BLUE}4)${NC} Live Docker Container Status    (docker ps snapshot)"
  echo "=========================================================="
}

if [ "$#" -eq 0 ]; then
  show_menu
  read -p "Select a log stream [1-4] (default: 1): " USER_CHOICE
  MODE="${USER_CHOICE:-1}"
fi

case "$MODE" in
  1)
    echo -e "${GREEN}📡 Streaming live startup-script logs via IAP tunnel... (Press Ctrl+C to exit)${NC}"
    gcloud compute ssh "$VM_NAME" \
      --zone="$ZONE" \
      --project="$PROJECT" \
      --tunnel-through-iap \
      --command="sudo journalctl -u google-startup-scripts.service -f --no-pager"
    ;;
  2)
    echo -e "${CYAN}🐳 Streaming live Docker Compose logs (Traefik, LLDAP, NetBird)... (Press Ctrl+C to exit)${NC}"
    gcloud compute ssh "$VM_NAME" \
      --zone="$ZONE" \
      --project="$PROJECT" \
      --tunnel-through-iap \
      --command="cd /opt/brainlab && sudo docker compose logs -f --tail=50"
    ;;
  3)
    echo -e "${YELLOW}📜 Fetching GCE Serial Console boot output...${NC}"
    gcloud compute instances get-serial-port-output "$VM_NAME" \
      --zone="$ZONE" \
      --project="$PROJECT" | tail -n 60
    ;;
  4)
    echo -e "${BLUE}🔍 Checking Docker container health on VM...${NC}"
    gcloud compute ssh "$VM_NAME" \
      --zone="$ZONE" \
      --project="$PROJECT" \
      --tunnel-through-iap \
      --command="sudo docker ps"
    ;;
  *)
    echo -e "${YELLOW}Usage: bash monitor_vm_logs.sh [1|2|3|4]${NC}"
    exit 1
    ;;
esac
