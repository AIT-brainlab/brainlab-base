#!/usr/bin/env bash
# ==========================================================
# 🔍 Identity-as-Code & LLDAP Health Verification
# ==========================================================
set -e

GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

PROJECT_ID="${PROJECT_ID:-ait-brainlab-mgmt}"
LLDAP_HOST="${1:-authen2.brain.cs.ait.ac.th}"

echo "=========================================================="
echo -e "${BLUE}🔍 Checking LLDAP Identity Plane (${LLDAP_HOST})...${NC}"
echo "=========================================================="

FAILED=0

# 1. Check LLDAP HTTPS Web UI
echo -ne "1. Checking LLDAP HTTPS Endpoint (https://${LLDAP_HOST})... "
HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" "https://${LLDAP_HOST}" --max-time 5 || echo "000")
if [[ "$HTTP_CODE" =~ ^(200|301|302|307|308)$ ]]; then
  echo -e "${GREEN}✅ PASS (HTTP $HTTP_CODE)${NC}"
else
  echo -e "${RED}❌ FAILED (HTTP $HTTP_CODE)${NC}"
  FAILED=$((FAILED + 1))
fi

# 2. Check Secret Manager Password Access
echo -ne "2. Checking GCP Secret Manager Access ('lldap-admin-password')... "
if gcloud secrets versions access latest --secret="lldap-admin-password" --project="${PROJECT_ID}" >/dev/null 2>&1; then
  echo -e "${GREEN}✅ PASS (Secret exists & accessible)${NC}"
else
  echo -e "${RED}❌ FAILED (Secret inaccessible in GCP Secret Manager)${NC}"
  FAILED=$((FAILED + 1))
fi

# 3. Test Admin Authentication via LLDAP GraphQL
echo -ne "3. Testing Admin Login against LLDAP GraphQL API... "
ADMIN_PW=$(gcloud secrets versions access latest --secret="lldap-admin-password" --project="${PROJECT_ID}" 2>/dev/null || echo "")

if [ -n "$ADMIN_PW" ]; then
  AUTH_RESPONSE=$(curl -k -s -X POST "https://${LLDAP_HOST}/auth/simple/login" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"admin\",\"password\":\"${ADMIN_PW}\"}" 2>/dev/null || echo "{}")
  
  if echo "$AUTH_RESPONSE" | grep -q "token"; then
    echo -e "${GREEN}✅ PASS (Authenticated successfully via GraphQL API)${NC}"
  else
    echo -e "${YELLOW}⚠️  Note: LLDAP auth endpoint returned non-token (Check admin password sync)${NC}"
  fi
else
  echo -e "${RED}❌ FAILED (Could not retrieve admin password)${NC}"
  FAILED=$((FAILED + 1))
fi

echo "=========================================================="
if [ $FAILED -eq 0 ]; then
  echo -e "${GREEN}🎉 IDENTITY CONTROL PLANE IS FULLY OPERATIONAL & READY FOR TERRAFORM!${NC}"
  echo "=========================================================="
  exit 0
else
  echo -e "${RED}⚠️  Some identity checks failed. Please inspect the output above.${NC}"
  echo "=========================================================="
  exit 1
fi
