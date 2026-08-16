# Authoritative Cloud DNS Managed Zones for AIT Brainlab & DPI Center

# Zone 1: brain.cs.ait.ac.th (Protected against accidental destroy)
resource "google_dns_managed_zone" "brainlab_zone" {
  name        = "brainlab-dns-zone"
  dns_name    = "brain.cs.ait.ac.th."
  description = "AIT Brainlab Authoritative DNS Zone"
  visibility  = "public"

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_project_service.mgmt_services]
}

# Zone 2: dpi.ait.ac.th (Protected against accidental destroy)
resource "google_dns_managed_zone" "dpi_zone" {
  name        = "dpi-dns-zone"
  dns_name    = "dpi.ait.ac.th."
  description = "DPI Center Authoritative DNS Zone"
  visibility  = "public"

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_project_service.mgmt_services]
}

# Initial A Record for On-Premise Primary Compute Node (la.cs.ait.ac.th)
resource "google_dns_record_set" "hub_record" {
  name         = "hub.brain.cs.ait.ac.th."
  managed_zone = google_dns_managed_zone.brainlab_zone.name
  type         = "A"
  ttl          = 300
  rrdatas      = [var.onprem_la_ip]

  depends_on = [google_dns_managed_zone.brainlab_zone]
}

# A Record for Tokyo Server (tokyo.cs.ait.ac.th - APIs & Web Demos)
resource "google_dns_record_set" "tokyo_record" {
  name         = "tokyo.brain.cs.ait.ac.th."
  managed_zone = google_dns_managed_zone.brainlab_zone.name
  type         = "A"
  ttl          = 300
  rrdatas      = [var.onprem_tokyo_ip]

  depends_on = [google_dns_managed_zone.brainlab_zone]
}
