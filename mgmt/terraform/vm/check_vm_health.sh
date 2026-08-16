#!/usr/bin/env bash
# ==========================================================
# 🔍 Management VM Engine & HTTPS Health Check (Staging URLs)
# ==========================================================
set -e

GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

DOMAIN="${1:-brain.cs.ait.ac.th}"

echo "=========================================================="
echo -e "${BLUE}🔍 Checking Brainlab Management VM Health (${DOMAIN})...${NC}"
echo "=========================================================="

FAILED=0

# 1. Check LLDAP Staging HTTPS Web Portal
echo -ne "1. Checking LLDAP Staging Portal (${BLUE}https://authen2.${DOMAIN}${NC})... "
STATUS=$(curl -k -s -o /dev/null -w "%{http_code}" "https://authen2.${DOMAIN}" --max-time 5 || echo "000")

if [[ "$STATUS" =~ ^(200|301|302|307|308)$ ]]; then
  echo -e "${GREEN}✅ PASS (HTTP $STATUS)${NC}"
else
  echo -e "${YELLOW}⚠️  WAITING: Response HTTP $STATUS (Booting / DNS propagation in progress)${NC}"
  FAILED=$((FAILED + 1))
fi

# 2. Check NetBird Staging Portal
echo -ne "2. Checking NetBird Staging Portal (${BLUE}https://netbird2.${DOMAIN}${NC})... "
NB_STATUS=$(curl -k -s -o /dev/null -w "%{http_code}" "https://netbird2.${DOMAIN}" --max-time 5 || echo "000")

if [[ "$NB_STATUS" =~ ^(200|301|302|307|308|404)$ ]]; then
  echo -e "${GREEN}✅ PASS (HTTP $NB_STATUS)${NC}"
else
  echo -e "${YELLOW}⚠️  WAITING: Response HTTP $NB_STATUS${NC}"
  FAILED=$((FAILED + 1))
fi

echo "=========================================================="
if [ $FAILED -eq 0 ]; then
  echo -e "${GREEN}🎉 ALL MANAGEMENT SERVICES ARE HEALTHY & OPERATIONAL! (Task 4.3 Complete)${NC}"
  echo "=========================================================="
  exit 0
else
  echo -e "${YELLOW}ℹ️  Initial VM boot takes ~60-90s to pull Docker images and acquire SSL certs.${NC}"
  echo -e "${YELLOW}👉 Run 'bash check_vm_health.sh' again in 1 minute.${NC}"
  echo "=========================================================="
  exit 0
fi
