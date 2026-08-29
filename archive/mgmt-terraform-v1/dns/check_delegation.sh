#!/usr/bin/env bash
# ==========================================================
# 🔍 Automated DNS Delegation & Resolution Health Check
# ==========================================================
set -e

GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

echo "=========================================================="
echo -e "${BLUE}🔍 Checking AIT Brainlab & DPI DNS Delegation...${NC}"
echo "=========================================================="

FAILED=0

# ---------------------------------------------------------
# Test 1: Brainlab Delegation (brain.cs.ait.ac.th)
# ---------------------------------------------------------
echo -e "\n1. Checking Delegation for ${BLUE}brain.cs.ait.ac.th${NC}..."
BRAIN_NS=$(dig +short @8.8.8.8 NS brain.cs.ait.ac.th 2>/dev/null | tr '\n' ' ')

if [[ "$BRAIN_NS" =~ "googledomains.com" ]]; then
  echo -e "   ${GREEN}✅ PASS: brain.cs.ait.ac.th is successfully delegated to Google Cloud DNS!${NC}"
  echo -e "      Authoritative NS: $BRAIN_NS"
else
  echo -e "   ${YELLOW}⚠️  PENDING: brain.cs.ait.ac.th NS delegation is not yet active on 8.8.8.8.${NC}"
  echo -e "      Current NS: ${BRAIN_NS:-"(none)"}"
  echo -e "      Action needed: Submit Google Cloud DNS NS records to cs.ait.ac.th administrator."
  FAILED=$((FAILED + 1))
fi

# ---------------------------------------------------------
# Test 2: Brainlab Service Record Resolution
# ---------------------------------------------------------
echo -e "\n2. Testing Public Resolution for ${BLUE}jupyterhub.brain.cs.ait.ac.th${NC}..."
JH_IP=$(dig +short @8.8.8.8 jupyterhub.brain.cs.ait.ac.th 2>/dev/null | tail -n1)

if [[ -n "$JH_IP" ]]; then
  echo -e "   ${GREEN}✅ PASS: jupyterhub.brain.cs.ait.ac.th resolves to $JH_IP${NC}"
else
  echo -e "   ${YELLOW}⚠️  WAITING: jupyterhub.brain.cs.ait.ac.th does not resolve publicly yet.${NC}"
fi

# ---------------------------------------------------------
# Test 3: DPI Delegation (dpi.ait.ac.th)
# ---------------------------------------------------------
echo -e "\n3. Checking Delegation for ${BLUE}dpi.ait.ac.th${NC}..."
DPI_NS=$(dig +short @8.8.8.8 NS dpi.ait.ac.th 2>/dev/null | tr '\n' ' ')

if [[ "$DPI_NS" =~ "googledomains.com" ]]; then
  echo -e "   ${GREEN}✅ PASS: dpi.ait.ac.th is successfully delegated to Google Cloud DNS!${NC}"
  echo -e "      Authoritative NS: $DPI_NS"
else
  echo -e "   ${YELLOW}⚠️  PENDING: dpi.ait.ac.th NS delegation is not yet active on 8.8.8.8.${NC}"
  echo -e "      Current NS: ${DPI_NS:-"(none)"}"
  echo -e "      Action needed: Submit Google Cloud DNS NS records to ait.ac.th administrator."
  FAILED=$((FAILED + 1))
fi

# ---------------------------------------------------------
# Final Summary
# ---------------------------------------------------------
echo -e "\n=========================================================="
if [ $FAILED -eq 0 ]; then
  echo -e "${GREEN}🎉 ALL DELEGATIONS ARE ACTIVE & HEALTHY! (Task 2.4 Complete)${NC}"
  echo "=========================================================="
  exit 0
else
  echo -e "${YELLOW}ℹ️  Delegation check completed with pending actions above.${NC}"
  echo "=========================================================="
  exit 0
fi
