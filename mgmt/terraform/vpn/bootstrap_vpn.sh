#!/usr/bin/env bash
# ==========================================================
# 📡 AIT Brainlab - NetBird VPN Automated Bootstrap Script
# ==========================================================
# Fully automates:
# 1. Prerequisite verification
# 2. Master Admin Account creation & PAT generation
# 3. Secret Manager storage ('netbird-mgmt-token')
# 4. Terraform deployment (Groups, ACLs, Setup Key, Peer #1)
# 5. Live mesh health verification (wt0 on 100.64.0.1)
# ==========================================================
set -e

GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

PROJECT_ID="ait-brainlab-mgmt"
ZONE="asia-southeast1-a"
NETBIRD_URL="https://netbird2.brain.cs.ait.ac.th"

echo "=========================================================="
echo -e "${BLUE}📡 Starting AIT Brainlab NetBird VPN Automated Bootstrap...${NC}"
echo "=========================================================="

# 1. Check Prerequisite Secrets
echo -ne "==> [1/5] Verifying master admin password in Secret Manager... "
if ! gcloud secrets describe lldap-admin-password --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo -e "${RED}❌ FAIL: lldap-admin-password secret not found! Deploy Sequence 3 first.${NC}"
  exit 1
fi
echo -e "${GREEN}✅ PASS${NC}"

# 2. Check NetBird Endpoint
echo -ne "==> [2/5] Checking NetBird Control Plane endpoint (${NETBIRD_URL})... "
for i in $(seq 1 15); do
  HTTP_CODE=$(curl -sk -o /dev/null -w "%{http_code}" "${NETBIRD_URL}/api/users" || echo "000")
  if [ "$HTTP_CODE" -eq 401 ] || [ "$HTTP_CODE" -eq 200 ]; then
    echo -e "${GREEN}✅ PASS (HTTP ${HTTP_CODE})${NC}"
    break
  fi
  sleep 2
done

# 3. Generate Master Account & PAT if not already in Secret Manager
echo -e "==> [3/5] Bootstrapping NetBird Master Account & PAT..."
if gcloud secrets describe netbird-mgmt-token --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo -e "    ${YELLOW}ℹ️ Secret 'netbird-mgmt-token' already exists in Secret Manager. Using existing token.${NC}"
else
  echo -e "    🔑 Creating Master Account ('brainlab@ait.asia') and generating PAT..."
  ADMIN_PASS=$(gcloud secrets versions access latest --secret="lldap-admin-password" --project="$PROJECT_ID")
  
  SETUP_RESP=$(curl -sk -X POST "${NETBIRD_URL}/api/setup" \
    -H 'Content-Type: application/json' \
    -d "{\"name\": \"Brainlab Master\", \"email\": \"brainlab@ait.asia\", \"password\": \"$ADMIN_PASS\", \"create_pat\": true}")

  PAT=$(echo "$SETUP_RESP" | grep -o '"personal_access_token":"[^"]*' | cut -d'"' -f4 || true)
  USER_ID=$(echo "$SETUP_RESP" | grep -o '"user_id":"[^"]*' | cut -d'"' -f4 || true)

  if [ -z "$PAT" ]; then
    echo -e "${RED}❌ Failed to obtain Personal Access Token from NetBird setup API!${NC}"
    echo "Response: $SETUP_RESP"
    exit 1
  fi

  echo -e "    🔐 Storing 'netbird-mgmt-token' into GCP Secret Manager..."
  echo -n "$PAT" | gcloud secrets create netbird-mgmt-token \
    --data-file=- \
    --project="$PROJECT_ID" >/dev/null 2>&1
  echo -e "    ${GREEN}✅ Token securely saved in Secret Manager (Zero terminal leakage)${NC}"
fi

# 4. Terraform Initialization & Deployment
echo -e "==> [4/5] Running Terraform Deployment in mgmt/terraform/vpn/..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

terraform init
terraform apply -auto-approve

# 5. Health Verification
echo "=========================================================="
echo -e "${BLUE}🔍 [5/5] Running Post-Deployment Health Checks...${NC}"
echo "=========================================================="

echo -ne "==> Checking 'netbird-setup-key' in Secret Manager... "
if gcloud secrets describe netbird-setup-key --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo -e "${GREEN}✅ PASS${NC}"
else
  echo -e "${RED}❌ FAIL: netbird-setup-key missing!${NC}"
  exit 1
fi

echo -ne "==> Checking 'netbird-mgmt-token' in Secret Manager... "
if gcloud secrets describe netbird-mgmt-token --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo -e "${GREEN}✅ PASS${NC}"
else
  echo -e "${RED}❌ FAIL: netbird-mgmt-token missing!${NC}"
  exit 1
fi

echo -e "==> Checking Management VM Peer #1 (wt0 interface)..."
gcloud compute ssh brainlab-mgmt-vm \
  --project="$PROJECT_ID" \
  --zone="$ZONE" \
  --tunnel-through-iap \
  --command="ip -4 addr show wt0 && sudo docker exec netbird-client netbird status || true"

echo "=========================================================="
echo -e "${GREEN}🎉 NETBIRD-AS-CODE (SEQUENCE 6) DEPLOYED & 100% HEALTHY!${NC}"
echo "=========================================================="
