terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "ait-brainlab-mgmt-tfstate"
    prefix = "vm"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Required GCP API for Compute Engine
resource "google_project_service" "compute_api" {
  project            = var.project_id
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

# ----------------------------------------------------------
# 🔐 Fetch Secrets from Secret Manager (Decoupled & Secure)
# ----------------------------------------------------------
data "google_secret_manager_secret_version" "jwt" {
  project = var.project_id
  secret  = "lldap-jwt"
  version = "latest"
}

data "google_secret_manager_secret_version" "admin_password" {
  project = var.project_id
  secret  = "lldap-admin-password"
  version = "latest"
}

# ----------------------------------------------------------
# 🌐 Reserved Static External Public IP
# ----------------------------------------------------------
resource "google_compute_address" "mgmt_ip" {
  name        = "brainlab-mgmt-static-ip"
  region      = var.region
  description = "Permanent static IP for AIT Brainlab Management Control Plane"
  depends_on  = [google_project_service.compute_api]

  lifecycle {
    prevent_destroy = true
  }
}

# ----------------------------------------------------------
# 🌐 Service DNS Ingress Records (Service-Bounded Context)
# ----------------------------------------------------------
# Automatically bind authen2.brain.cs.ait.ac.th to this VM's Static IP
resource "google_dns_record_set" "authen2" {
  name         = "${var.lldap_staging_subdomain}.${var.domain}."
  type         = "A"
  ttl          = 300
  managed_zone = "ait-brainlab"
  rrdatas      = [google_compute_address.mgmt_ip.address]
  depends_on   = [google_compute_address.mgmt_ip]
}

# Automatically bind netbird2.brain.cs.ait.ac.th to this VM's Static IP
resource "google_dns_record_set" "netbird2" {
  name         = "${var.netbird_staging_subdomain}.${var.domain}."
  type         = "A"
  ttl          = 300
  managed_zone = "ait-brainlab"
  rrdatas      = [google_compute_address.mgmt_ip.address]
  depends_on   = [google_compute_address.mgmt_ip]
}

# ----------------------------------------------------------
# 🛡️ Firewall Security Rules (Zero-Trust)
# ----------------------------------------------------------
# 1. Allow Web Traffic (HTTP 80 for ACME SSL, HTTPS 443 for Web Portals)
resource "google_compute_firewall" "allow_web" {
  name        = "brainlab-mgmt-allow-web"
  network     = "default"
  description = "Allow HTTP and HTTPS traffic for Traefik edge proxy"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["brainlab-mgmt-node"]
  depends_on    = [google_project_service.compute_api]
}

# 2. Allow NetBird WireGuard Signal & STUN (Public Broker)
resource "google_compute_firewall" "allow_netbird" {
  name        = "brainlab-mgmt-allow-netbird"
  network     = "default"
  description = "Allow NetBird WireGuard signal and relay traffic"

  allow {
    protocol = "tcp"
    ports    = ["33073"]
  }

  allow {
    protocol = "udp"
    ports    = ["33073"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["brainlab-mgmt-node"]
  depends_on    = [google_project_service.compute_api]
}

# 3. Allow SSH STRICTLY via Google Cloud Identity-Aware Proxy (IAP)
resource "google_compute_firewall" "allow_iap_ssh" {
  name        = "brainlab-mgmt-allow-iap-ssh"
  network     = "default"
  description = "Allow SSH strictly through Google Cloud Identity-Aware Proxy (IAP)"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["brainlab-mgmt-node"]
  depends_on    = [google_project_service.compute_api]
}

# ----------------------------------------------------------
# 🖥️ Disposable Compute VM Instance ("100% Cattle")
# ----------------------------------------------------------
locals {
  docker_compose_rendered = templatefile("${path.module}/templates/docker-compose.yml.tftpl", {
    domain                    = var.domain
    lldap_subdomain           = var.lldap_subdomain
    lldap_staging_subdomain   = var.lldap_staging_subdomain
    netbird_subdomain         = var.netbird_subdomain
    netbird_staging_subdomain = var.netbird_staging_subdomain
    acme_email                = var.acme_email
  })

  startup_script_rendered = templatefile("${path.module}/templates/startup-script.sh.tftpl", {
    docker_compose_content    = local.docker_compose_rendered
    lldap_jwt_secret          = data.google_secret_manager_secret_version.jwt.secret_data
    lldap_admin_password      = data.google_secret_manager_secret_version.admin_password.secret_data
    domain                    = var.domain
    netbird_staging_subdomain = var.netbird_staging_subdomain
    project_id                = var.project_id
  })
}

resource "google_compute_instance" "mgmt_vm" {
  name         = "brainlab-mgmt-vm"
  machine_type = var.machine_type
  zone         = var.zone
  description  = "AIT Brainlab 100% Stateless Management Plane (Traefik, LLDAP, NetBird)"

  tags = ["brainlab-mgmt-node"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.mgmt_ip.address
    }
  }

  # Native GCE Automated Startup Script
  metadata_startup_script = local.startup_script_rendered

  lifecycle {
    ignore_changes = [metadata_startup_script]
  }

  # Ensure API & Network are completely ready before provisioning
  depends_on = [
    google_project_service.compute_api,
    google_compute_firewall.allow_web,
    google_compute_firewall.allow_netbird,
    google_compute_firewall.allow_iap_ssh,
    google_dns_record_set.authen2,
    google_dns_record_set.netbird2,
  ]
}

# ==========================================================
# ⏳ Live Bootstrap Streamer & Health Check Waiter
# ==========================================================
resource "terraform_data" "wait_for_vm_init" {
  depends_on = [
    google_compute_instance.mgmt_vm,
    google_dns_record_set.authen2,
    google_dns_record_set.netbird2,
  ]

  triggers_replace = [
    google_compute_instance.mgmt_vm.id,
    google_compute_instance.mgmt_vm.metadata_startup_script,
  ]

  provisioner "local-exec" {
    command = "bash ${path.module}/wait_for_bootstrap.sh ${google_compute_instance.mgmt_vm.name} ${var.zone} ${var.project_id}"
  }
}
