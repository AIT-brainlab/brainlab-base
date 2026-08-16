#!/usr/bin/env bash
# AIT Brainlab - DNS Verification Script
# Usage: ./verify_dns.sh [DOMAIN]

set -euo pipefail

DOMAIN="${1:-brain.cs.ait.ac.th}"

echo "=========================================================="
echo " Checking DNS resolution for: ${DOMAIN}"
echo "=========================================================="

echo -e "\n1. Public Google DNS (8.8.8.8):"
dig @8.8.8.8 "${DOMAIN}" +short || echo "Failed to resolve via 8.8.8.8"

echo -e "\n2. Cloudflare DNS (1.1.1.1):"
dig @1.1.1.1 "${DOMAIN}" +short || echo "Failed to resolve via 1.1.1.1"

echo -e "\n3. Checking NS Records for ${DOMAIN}:"
dig NS "${DOMAIN}" +short || echo "Failed to fetch NS records"

echo -e "\n4. Authoritative Name Server Test (GCP Cloud DNS):"
dig @ns-cloud-a1.googledomains.com "${DOMAIN}" +short || echo "GCP NS not reachable or records not replicated yet."

echo -e "\n=========================================================="
echo " Verification Complete."
echo "=========================================================="
