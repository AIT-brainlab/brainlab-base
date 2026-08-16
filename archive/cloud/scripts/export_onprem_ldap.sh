#!/usr/bin/env bash
# AIT Brainlab - Export On-Premise LDAP User Accounts and Posix Attributes
# Usage: ./export_onprem_ldap.sh

set -euo pipefail

OUTPUT_FILE="exported_ldap_users_$(date +%Y%m%d).ldif"
LDAP_HOST="${LDAP_HOST:-ldap.brainlab}"
BASE_DN="${BASE_DN:-dc=ldap,dc=brainlab}"

echo "==> Exporting posixAccount entries from ${LDAP_HOST}..."

ldapsearch -x -H "ldap://${LDAP_HOST}" -b "${BASE_DN}" \
  "(objectClass=posixAccount)" \
  uid uidNumber gidNumber homeDirectory mail \
  > "${OUTPUT_FILE}"

echo "==> Export completed successfully: ${OUTPUT_FILE}"
echo "==> Summary of exported users:"
grep "^uid:" "${OUTPUT_FILE}" | awk '{print $2}'
