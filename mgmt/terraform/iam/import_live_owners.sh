#!/usr/bin/env bash
# ==========================================
# 📥 Automated IAM Live State Importer
# ==========================================
set -e

PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "ait-brainlab-mgmt")

echo "=========================================="
echo "🔍 Fetching live Project Owners from GCP ($PROJECT_ID)..."
echo "=========================================="

OWNERS=$(gcloud projects get-iam-policy "$PROJECT_ID" \
  --flatten="bindings[].members" \
  --format="value(bindings.members)" \
  --filter="bindings.role:roles/owner")

for MEMBER in $OWNERS; do
  echo "==> Importing $MEMBER as roles/owner into Terraform state..."
  terraform import "google_project_iam_member.owners[\"$MEMBER\"]" "$PROJECT_ID roles/owner $MEMBER" || true
done

echo ""
echo "=========================================="
echo "✅ Done importing live IAM owners!"
echo "👉 Run 'terraform plan' to verify alignment with zero drift."
echo "=========================================="
