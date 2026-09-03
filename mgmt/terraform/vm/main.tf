# ==========================================================
# 🖥️ AIT Brainlab - Disposable Management VM Engine
# ==========================================================
# 100% Stateless & Self-Healing Control Plane ("Cattle, not Pets")
# - Runs Traefik v3, LLDAP, NetBird Management, Signal, and Client
# - Automatically binds authen2 and netbird2 to its dynamic ephemeral IP
# - Hydrates SQLite databases from GCS in 1 second on boot
# ==========================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
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

data "google_secret_manager_secret_version" "google_oauth_client_id" {
  project = var.project_id
  secret  = "google-oauth-client-id"
  version = "latest"
}

data "google_secret_manager_secret_version" "google_oauth_client_secret" {
  project = var.project_id
  secret  = "google-oauth-client-secret"
  version = "latest"
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
    ports    = ["33073", "51820"]
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
resource "random_password" "netbird_relay_secret" {
  length  = 64
  special = false
}

locals {
  docker_compose_rendered = templatefile("${path.module}/templates/docker-compose.yml.tftpl", {
    domain            = var.domain
    lldap_subdomain   = var.lldap_subdomain
    netbird_subdomain = var.netbird_subdomain
    acme_email        = var.acme_email
    netbird_version   = var.netbird_version
    lldap_version     = var.lldap_version
    traefik_version   = var.traefik_version
  })

  startup_script_rendered = templatefile("${path.module}/templates/startup-script.sh.tftpl", {
    docker_compose_content     = local.docker_compose_rendered
    lldap_jwt_secret           = data.google_secret_manager_secret_version.jwt.secret_data
    lldap_admin_password       = data.google_secret_manager_secret_version.admin_password.secret_data
    google_oauth_client_id     = data.google_secret_manager_secret_version.google_oauth_client_id.secret_data
    google_oauth_client_secret = data.google_secret_manager_secret_version.google_oauth_client_secret.secret_data
    netbird_relay_secret       = random_password.netbird_relay_secret.result
    domain                     = var.domain
    lldap_subdomain            = var.lldap_subdomain
    netbird_subdomain          = var.netbird_subdomain
    project_id                 = var.project_id
    state_bucket               = var.state_bucket
  })
}

resource "google_compute_instance" "mgmt_vm" {
  name                      = "brainlab-mgmt-vm"
  machine_type              = var.machine_type
  zone                      = var.zone
  description               = "AIT Brainlab 100% Stateless Management Plane (Traefik, LLDAP, NetBird)"
  allow_stopping_for_update = true

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
      // Dynamic Ephemeral Public IP ($0 cost when destroyed)
    }
  }

  # Service Account Attachment for Autonomous GCP Secret Manager Access
  service_account {
    email  = "brainlab-mgmt-terraform@${var.project_id}.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

  metadata = {
    ssh-keys = "ubuntu:${trimspace(file("${path.module}/../../keys/brainlab-admin-key.pub"))}"
  }

  # Native GCE Automated Startup Script
  metadata_startup_script = local.startup_script_rendered

  lifecycle {
    ignore_changes = [
      metadata_startup_script,
      boot_disk[0].initialize_params[0].image,
    ]
  }

  depends_on = [
    google_project_service.compute_api,
    google_compute_firewall.allow_web,
    google_compute_firewall.allow_netbird,
    google_compute_firewall.allow_iap_ssh,
  ]
}

# ----------------------------------------------------------
# 🌐 Dynamic DNS Bindings (Points to VM Ephemeral Public IP)
# ----------------------------------------------------------
# Primary LDAP Directory Service DNS
resource "google_dns_record_set" "ldap" {
  name         = "${var.lldap_subdomain}.${var.domain}."
  type         = "A"
  ttl          = 300
  managed_zone = "ait-brainlab"
  rrdatas      = [google_compute_instance.mgmt_vm.network_interface[0].access_config[0].nat_ip]
  depends_on   = [google_compute_instance.mgmt_vm]
}

# NetBird VPN DNS
resource "google_dns_record_set" "netbird" {
  name         = "${var.netbird_subdomain}.${var.domain}."
  type         = "A"
  ttl          = 300
  managed_zone = "ait-brainlab"
  rrdatas      = [google_compute_instance.mgmt_vm.network_interface[0].access_config[0].nat_ip]
  depends_on   = [google_compute_instance.mgmt_vm]
}

# ==========================================================
# ⏳ Live Bootstrap Streamer & Health Check Waiter
# ==========================================================
resource "terraform_data" "wait_for_vm_init" {
  depends_on = [
    google_compute_instance.mgmt_vm,
    google_dns_record_set.ldap,
    google_dns_record_set.netbird,
  ]

  triggers_replace = [
    google_compute_instance.mgmt_vm.id,
    google_compute_instance.mgmt_vm.metadata_startup_script,
  ]

  provisioner "local-exec" {
    command = "bash ${path.module}/wait_for_bootstrap.sh ${google_compute_instance.mgmt_vm.name} ${var.zone} ${var.project_id}"
  }
}
