#!/usr/bin/env bash
# ==========================================================
# 📥 Automated DNS Live State Importer / Disaster Recovery
# ==========================================================
set -e

PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "ait-brainlab-mgmt")

echo "=========================================================="
echo "🌐 Adopting Cloud DNS into Terraform State ($PROJECT_ID)..."
echo "=========================================================="

echo "==> 1. Importing Managed Zones..."
terraform import google_dns_managed_zone.brainlab_zone "$PROJECT_ID/ait-brainlab" || true
terraform import google_dns_managed_zone.dpi_zone "$PROJECT_ID/dpi-center" || true

echo "==> 2. Importing brain.cs.ait.ac.th A Records..."
RECORDS=(
  "authen"
  "aitgpt_dev:aitgpt.dev.brain.cs.ait.ac.th."
  "wildcard_aitgpt_dev:\\*.aitgpt.dev.brain.cs.ait.ac.th."
  "httpd"
  "jupyterhub"
  "litellm"
  "ml"
  "wildcard_ml:\\*.ml.brain.cs.ait.ac.th."
  "mlflow_ml:mlflow.ml.brain.cs.ait.ac.th."
  "traefik_ml:traefik.ml.brain.cs.ait.ac.th."
  "netbird"
  "nexterm"
  "openwebui"
  "traefik"
)

for ITEM in "${RECORDS[@]}"; do
  KEY="${ITEM%%:*}"
  if [[ "$ITEM" == *":"* ]]; then
    DOMAIN="${ITEM##*:}"
  else
    DOMAIN="${KEY}.brain.cs.ait.ac.th."
  fi
  echo "    Importing record: $DOMAIN (Key: $KEY)"
  terraform import "google_dns_record_set.brainlab_a_records[\"$KEY\"]" "$PROJECT_ID/ait-brainlab/$DOMAIN/A" || true
done

echo "==> 3. Importing dpi.ait.ac.th Records..."
terraform import google_dns_record_set.dpi_mx "$PROJECT_ID/dpi-center/dpi.ait.ac.th./MX" || true
terraform import google_dns_record_set.dpi_txt "$PROJECT_ID/dpi-center/dpi.ait.ac.th./TXT" || true
terraform import google_dns_record_set.dpi_sandbox_ns "$PROJECT_ID/dpi-center/sandbox-a.dpi.ait.ac.th./NS" || true
terraform import google_dns_record_set.dpi_www "$PROJECT_ID/dpi-center/www.dpi.ait.ac.th./A" || true

echo ""
echo "=========================================================="
echo "✅ All live DNS zones and records adopted into state!"
echo "👉 Run 'terraform plan' to verify."
echo "=========================================================="
