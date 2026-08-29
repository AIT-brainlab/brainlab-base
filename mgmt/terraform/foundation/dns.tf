# ==========================================================
# 🌐 Cloud DNS Authoritative Zones & Production Records
# ==========================================================

# Ensure Cloud DNS API is enabled
resource "google_project_service" "dns_api" {
  project            = var.project_id
  service            = "dns.googleapis.com"
  disable_on_destroy = false
}

# ----------------------------------------------------------
# 1. Authoritative Zone: brain.cs.ait.ac.th
# ----------------------------------------------------------
resource "google_dns_managed_zone" "brainlab_zone" {
  name        = "ait-brainlab"
  dns_name    = "brain.cs.ait.ac.th."
  description = "AIT Brainlab domain"
  visibility  = "public"

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_project_service.dns_api]
}

# Live A Records in brain.cs.ait.ac.th
locals {
  brainlab_records = {
    "authen"              = { name = "authen.brain.cs.ait.ac.th.", ip = "192.41.170.39", ttl = 300 }
    "aitgpt_dev"          = { name = "aitgpt.dev.brain.cs.ait.ac.th.", ip = "192.41.170.17", ttl = 300 }
    "wildcard_aitgpt_dev" = { name = "*.aitgpt.dev.brain.cs.ait.ac.th.", ip = "192.41.170.17", ttl = 300 }
    "httpd"               = { name = "httpd.brain.cs.ait.ac.th.", ip = "192.41.170.39", ttl = 300 }
    "jupyterhub"          = { name = "jupyterhub.brain.cs.ait.ac.th.", ip = "192.41.170.39", ttl = 300 }
    "litellm"             = { name = "litellm.brain.cs.ait.ac.th.", ip = "192.41.170.39", ttl = 300 }
    "ml"                  = { name = "ml.brain.cs.ait.ac.th.", ip = "192.41.170.105", ttl = 300 }
    "wildcard_ml"         = { name = "*.ml.brain.cs.ait.ac.th.", ip = "192.41.170.105", ttl = 300 }
    "mlflow_ml"           = { name = "mlflow.ml.brain.cs.ait.ac.th.", ip = "192.41.170.105", ttl = 300 }
    "traefik_ml"          = { name = "traefik.ml.brain.cs.ait.ac.th.", ip = "192.41.170.105", ttl = 300 }
    "netbird"             = { name = "netbird.brain.cs.ait.ac.th.", ip = "192.41.170.39", ttl = 300 }
    "nexterm"             = { name = "nexterm.brain.cs.ait.ac.th.", ip = "192.41.170.39", ttl = 300 }
    "openwebui"           = { name = "openwebui.brain.cs.ait.ac.th.", ip = "192.41.170.39", ttl = 300 }
    "traefik"             = { name = "traefik.brain.cs.ait.ac.th.", ip = "192.41.170.39", ttl = 300 }
  }
}

resource "google_dns_record_set" "brainlab_a_records" {
  for_each = local.brainlab_records

  name         = each.value.name
  managed_zone = google_dns_managed_zone.brainlab_zone.name
  type         = "A"
  ttl          = each.value.ttl
  rrdatas      = [each.value.ip]
}

# ----------------------------------------------------------
# 2. Authoritative Zone: dpi.ait.ac.th
# ----------------------------------------------------------
resource "google_dns_managed_zone" "dpi_zone" {
  name        = "dpi-center"
  dns_name    = "dpi.ait.ac.th."
  description = "DPI center domain"
  visibility  = "public"

  dnssec_config {
    state = "off"
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_project_service.dns_api]
}

# DPI MX Record
resource "google_dns_record_set" "dpi_mx" {
  name         = "dpi.ait.ac.th."
  managed_zone = google_dns_managed_zone.dpi_zone.name
  type         = "MX"
  ttl          = 216000
  rrdatas = [
    "10 mx1.improvmx.com.",
    "20 mx2.improvmx.com."
  ]
}

# DPI TXT (SPF) Record
resource "google_dns_record_set" "dpi_txt" {
  name         = "dpi.ait.ac.th."
  managed_zone = google_dns_managed_zone.dpi_zone.name
  type         = "TXT"
  ttl          = 216000
  rrdatas = [
    "\"v=spf1 include:spf.improvmx.com ~all\""
  ]
}

# DPI AWS Sandbox Subdelegation (NS)
resource "google_dns_record_set" "dpi_sandbox_ns" {
  name         = "sandbox-a.dpi.ait.ac.th."
  managed_zone = google_dns_managed_zone.dpi_zone.name
  type         = "NS"
  ttl          = 300
  rrdatas = [
    "ns-369.awsdns-46.com.",
    "ns-985.awsdns-59.net.",
    "ns-1212.awsdns-23.org.",
    "ns-2013.awsdns-59.co.uk."
  ]
}

# DPI Web Server (A Record)
resource "google_dns_record_set" "dpi_www" {
  name         = "www.dpi.ait.ac.th."
  managed_zone = google_dns_managed_zone.dpi_zone.name
  type         = "A"
  ttl          = 216000
  rrdatas      = ["192.168.1.10"]
}
