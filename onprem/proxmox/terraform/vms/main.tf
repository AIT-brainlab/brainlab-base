# ==========================================================
# 🖥️ AIT Brainlab - Proxmox VE Application VM Provisioner
# ==========================================================
# Modular structure:
#   - vm-proxy.tf:    VM 100 (brainlab-proxy)
#   - vm-services.tf: VM 120 (brainlab-services)
#   - vm-dlms.tf:     VM 119 (dlms-server)
#   - vm-dlms-prd.tf: VM 118 (dlms-prd - Docker Swarm Node)
#   - routes.tf:      Traefik dynamic ingress routes & NetBird sync
# Provider: bpg/proxmox
# ==========================================================

# Data Sources (Read-Only Proxmox Environment Awareness)
data "proxmox_virtual_environment_datastores" "host_datastores" {
  node_name = var.target_node
}

data "proxmox_virtual_environment_vms" "host_vms" {
  node_name = var.target_node
}

data "proxmox_virtual_environment_dns" "host_dns" {
  node_name = var.target_node
}
