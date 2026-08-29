# Authoritative Cloud DNS Zone: brain.cs.ait.ac.th

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
