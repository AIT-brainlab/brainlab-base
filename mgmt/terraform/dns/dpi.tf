# Authoritative Cloud DNS Zone: dpi.ait.ac.th

resource "google_dns_managed_zone" "dpi_zone" {
  name        = "dpi-center"
  dns_name    = "dpi.ait.ac.th."
  description = "DPI center domain"
  visibility  = "public"

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
  rrdatas      = [
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
  rrdatas      = [
    "\"v=spf1 include:spf.improvmx.com ~all\""
  ]
}

# DPI AWS Sandbox Subdelegation (NS)
resource "google_dns_record_set" "dpi_sandbox_ns" {
  name         = "sandbox-a.dpi.ait.ac.th."
  managed_zone = google_dns_managed_zone.dpi_zone.name
  type         = "NS"
  ttl          = 300
  rrdatas      = [
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
