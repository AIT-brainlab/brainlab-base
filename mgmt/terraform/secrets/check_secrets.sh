#!/usr/bin/env bash
# ==========================================================
# 🔐 Secret Manager Existence & Health Check (Zero Leakage)
# ==========================================================
set -e

GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "ait-brainlab-mgmt")

echo "=========================================================="
echo -e "${BLUE}🔐 Verifying Secret Manager Objects in ${PROJECT_ID}...${NC}"
echo -e "🛡️  ${YELLOW}(Secret values are intentionally hidden for security)${NC}"
echo "=========================================================="

SECRETS=("lldap-jwt" "lldap-admin-password")
FAILED=0

for SECRET in "${SECRETS[@]}"; do
  echo -ne "==> Checking secret '${BLUE}${SECRET}${NC}'... "
  
  if gcloud secrets describe "$SECRET" --project="$PROJECT_ID" >/dev/null 2>&1; then
    ACTIVE_VERSION=$(gcloud secrets versions list "$SECRET" --project="$PROJECT_ID" --filter="state:ENABLED" --format="value(name)" 2>/dev/null | head -n1)
    
    if [ -n "$ACTIVE_VERSION" ]; then
      echo -e "${GREEN}✅ PASS (Active Version: $ACTIVE_VERSION, State: ENABLED)${NC}"
    else
      echo -e "${YELLOW}⚠️  WARNING: Secret exists but has no ENABLED versions.${NC}"
      FAILED=$((FAILED + 1))
    fi
  else
    echo -e "${RED}❌ FAIL: Secret not found in Secret Manager.${NC}"
    FAILED=$((FAILED + 1))
  fi
done

echo "=========================================================="
if [ $FAILED -eq 0 ]; then
  echo -e "${GREEN}🎉 ALL REQUIRED SECRETS EXIST & ARE SECURELY STORED! (Task 3.2 Complete)${NC}"
  echo "=========================================================="
  exit 0
else
  echo -e "${RED}❌ Some secrets are missing or not enabled. Check terraform apply output.${NC}"
  echo "=========================================================="
  exit 1
fi
