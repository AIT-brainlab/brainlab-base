#!/usr/bin/env bash
set -e

echo "==> Importing Cloud DNS Managed Zones..."
terraform import google_dns_managed_zone.brainlab_zone ait-brainlab || true
terraform import google_dns_managed_zone.dpi_zone dpi-center || true

echo "==> Importing brain.cs.ait.ac.th A Records..."
terraform import 'google_dns_record_set.brainlab_a_records["authen"]' ait-brainlab-mgmt/ait-brainlab/authen.brain.cs.ait.ac.th./A || true
terraform import 'google_dns_record_set.brainlab_a_records["aitgpt_dev"]' ait-brainlab-mgmt/ait-brainlab/aitgpt.dev.brain.cs.ait.ac.th./A || true
terraform import 'google_dns_record_set.brainlab_a_records["wildcard_aitgpt_dev"]' ait-brainlab-mgmt/ait-brainlab/\*.aitgpt.dev.brain.cs.ait.ac.th./A || true
terraform import 'google_dns_record_set.brainlab_a_records["httpd"]' ait-brainlab-mgmt/ait-brainlab/httpd.brain.cs.ait.ac.th./A || true
terraform import 'google_dns_record_set.brainlab_a_records["jupyterhub"]' ait-brainlab-mgmt/ait-brainlab/jupyterhub.brain.cs.ait.ac.th./A || true
terraform import 'google_dns_record_set.brainlab_a_records["litellm"]' ait-brainlab-mgmt/ait-brainlab/litellm.brain.cs.ait.ac.th./A || true
terraform import 'google_dns_record_set.brainlab_a_records["ml"]' ait-brainlab-mgmt/ait-brainlab/ml.brain.cs.ait.ac.th./A || true
terraform import 'google_dns_record_set.brainlab_a_records["wildcard_ml"]' ait-brainlab-mgmt/ait-brainlab/\*.ml.brain.cs.ait.ac.th./A || true
terraform import 'google_dns_record_set.brainlab_a_records["mlflow_ml"]' ait-brainlab-mgmt/ait-brainlab/mlflow.ml.brain.cs.ait.ac.th./A || true
terraform import 'google_dns_record_set.brainlab_a_records["traefik_ml"]' ait-brainlab-mgmt/ait-brainlab/traefik.ml.brain.cs.ait.ac.th./A || true
terraform import 'google_dns_record_set.brainlab_a_records["netbird"]' ait-brainlab-mgmt/ait-brainlab/netbird.brain.cs.ait.ac.th./A || true
terraform import 'google_dns_record_set.brainlab_a_records["nexterm"]' ait-brainlab-mgmt/ait-brainlab/nexterm.brain.cs.ait.ac.th./A || true
terraform import 'google_dns_record_set.brainlab_a_records["openwebui"]' ait-brainlab-mgmt/ait-brainlab/openwebui.brain.cs.ait.ac.th./A || true
terraform import 'google_dns_record_set.brainlab_a_records["traefik"]' ait-brainlab-mgmt/ait-brainlab/traefik.brain.cs.ait.ac.th./A || true

echo "==> Importing dpi.ait.ac.th Records..."
terraform import google_dns_record_set.dpi_mx ait-brainlab-mgmt/dpi-center/dpi.ait.ac.th./MX || true
terraform import google_dns_record_set.dpi_txt ait-brainlab-mgmt/dpi-center/dpi.ait.ac.th./TXT || true
terraform import google_dns_record_set.dpi_sandbox_ns ait-brainlab-mgmt/dpi-center/sandbox-a.dpi.ait.ac.th./NS || true
terraform import google_dns_record_set.dpi_www ait-brainlab-mgmt/dpi-center/www.dpi.ait.ac.th./A || true

echo "==> Done importing! Run 'terraform plan' to verify."
