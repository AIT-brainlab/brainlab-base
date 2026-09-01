# ==========================================================
# 🛡️ AIT Brainlab Core Infrastructure VMs (VM 100 & VM 120)
# ==========================================================
# VM 100: brainlab-proxy (10G Traefik Edge SSL/HTTP Ingress)
# VM 120: brainlab-services (Web Printing Portal & Lab Administration)
# ==========================================================

# 1. Cloud-Init Snippet for VM 100 (brainlab-proxy)
resource "proxmox_virtual_environment_file" "cloud_user_data_proxy" {
  content_type = "snippets"
  datastore_id = var.snippet_datastore_id
  node_name    = var.target_node

  source_raw {
    data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
      vm_name             = "brainlab-proxy"
      netbird_setup_key   = var.netbird_brainlab_cluster_key
      ssh_public_keys     = var.ssh_public_keys
      dynamic_routes_yaml = ""
    })

    file_name = "cloud-init-brainlab-proxy.yaml"
  }
}

# 2. VM 100: On-Premise 10G Edge Proxy (Traefik SSL/HTTP Edge Proxy)
resource "proxmox_virtual_environment_vm" "proxy" {
  name        = "brainlab-proxy"
  description = "AIT Brainlab On-Premise 10G Edge Proxy VM (Traefik SSL/HTTP Edge Proxy)"
  node_name   = var.target_node
  vm_id       = 100
  tags        = ["brainlab", "onprem", "proxy", "edge"]

  agent {
    enabled = true
    timeout = "1s"
  }

  cpu {
    cores = var.proxy_cores
    type  = "host"
  }

  memory {
    dedicated = var.proxy_memory
  }

  disk {
    datastore_id = var.datastore_id
    file_id      = "local:iso/ubuntu-24.04-minimal-cloudimg-amd64.img"
    interface    = "scsi0"
    size         = var.proxy_disk_size
  }

  # net0: Frontend Physical 10G CSIM LAN
  network_device {
    bridge = "vmbr1"
  }

  # net1: Internal Proxmox SDN NAT VNet (direct L2 access to tenant VMs)
  network_device {
    bridge = var.bridge
  }

  initialization {
    datastore_id = var.datastore_id

    ip_config {
      ipv4 {
        address = var.proxy_ip
        gateway = var.proxy_gateway
      }
    }

    ip_config {
      ipv4 {
        address = "10.10.250.100/16"
      }
    }

    dns {
      servers = ["192.41.170.15"]
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_user_data_proxy.id
  }

  lifecycle {
    ignore_changes = [
      initialization[0].user_data_file_id,
    ]
  }
}

# 3. Cloud-Init Snippet for VM 120 (brainlab-services)
resource "proxmox_virtual_environment_file" "cloud_user_data_services" {
  content_type = "snippets"
  datastore_id = var.snippet_datastore_id
  node_name    = var.target_node

  source_raw {
    data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
      vm_name             = "brainlab-services"
      netbird_setup_key   = var.netbird_brainlab_cluster_key
      ssh_public_keys     = var.ssh_public_keys
      dynamic_routes_yaml = ""
    })

    file_name = "cloud-init-brainlab-services.yaml"
  }
}

# 4. VM 120: General Lab Administrative Services (Web Printing Portal & Lab Tools)
resource "proxmox_virtual_environment_vm" "brainlab_services" {
  name        = "brainlab-services"
  description = "AIT Brainlab General Services VM (Web Printing Portal & Lab Administration)"
  node_name   = var.target_node
  vm_id       = 120
  tags        = ["brainlab", "onprem", "services", "web-print"]

  agent {
    enabled = true
    timeout = "1s"
  }

  cpu {
    cores = var.services_cores
    type  = "host"
  }

  memory {
    dedicated = var.services_memory
  }

  disk {
    datastore_id = var.datastore_id
    file_id      = "local:iso/ubuntu-24.04-minimal-cloudimg-amd64.img"
    interface    = "scsi0"
    size         = var.services_disk_size
  }

  network_device {
    bridge = var.bridge
  }

  initialization {
    datastore_id = var.datastore_id

    ip_config {
      ipv4 {
        address = "10.10.250.120/16"
        gateway = "10.10.0.1"
      }
    }

    dns {
      servers = ["192.41.170.15", "8.8.8.8"]
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_user_data_services.id
  }

  lifecycle {
    ignore_changes = [
      initialization[0].user_data_file_id,
    ]
  }
}
