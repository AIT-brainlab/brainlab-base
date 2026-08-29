terraform {
  required_version = ">= 1.5.0"
  required_providers {
    lldap = {
      source  = "tasansga/lldap"
      version = "~> 0.4.2"
    }
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
    prefix = "identity"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Fetch LLDAP Admin Password securely from Secret Manager
data "google_secret_manager_secret_version" "lldap_admin_password" {
  secret  = "lldap-admin-password"
  project = var.project_id
}

# Configure LLDAP Provider
provider "lldap" {
  http_url = var.lldap_http_url
  ldap_url = var.lldap_ldap_url
  username = var.lldap_admin_user
  password = data.google_secret_manager_secret_version.lldap_admin_password.secret_data
  base_dn  = var.base_dn
}
