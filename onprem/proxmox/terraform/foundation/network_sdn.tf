# ==========================================================
# 🌐 AIT Brainlab - Proxmox Host Network Ports & SDN IaC
# ==========================================================
# Declaratively manages Proxmox Host Bridges (vmbr0, vmbr1, vmbr2)
# and Proxmox Software-Defined Networks (SDN) with dnsmasq DHCP.
# ==========================================================

# 1. Proxmox Host Network Interface Bridges Configuration
resource "terraform_data" "proxmox_network_bridges" {
  triggers_replace = [
    var.target_node
  ]

  provisioner "local-exec" {
    command = <<EOT
      # Configure vmbr0 (NAT Bridge)
      curl -k -s -H "Authorization: PVEAPIToken=${var.proxmox_api_token}" \
        -X POST "${var.proxmox_endpoint}api2/json/nodes/${var.target_node}/network" \
        -d "iface=vmbr0&type=bridge&autostart=1&cidr=10.10.20.1/24&comments=NAT%20Bridge%20to%20Management%20Port" || true

      # Configure vmbr1 (10G Frontend Port enp2s0)
      curl -k -s -H "Authorization: PVEAPIToken=${var.proxmox_api_token}" \
        -X POST "${var.proxmox_endpoint}api2/json/nodes/${var.target_node}/network" \
        -d "iface=vmbr1&type=bridge&autostart=1&bridge_ports=enp2s0&comments=Frontend%2010G%20High-Speed%20Port" || true

      # Configure vmbr2 (Backend Private Subnet)
      curl -k -s -H "Authorization: PVEAPIToken=${var.proxmox_api_token}" \
        -X POST "${var.proxmox_endpoint}api2/json/nodes/${var.target_node}/network" \
        -d "iface=vmbr2&type=bridge&autostart=1&cidr=10.10.30.1/24&comments=Backend%20Private%20Subnet" || true
    EOT
  }
}

# 2. Proxmox SDN Zone & VNet Declarative Provisioner
resource "terraform_data" "proxmox_sdn_provisioner" {
  depends_on = [terraform_data.proxmox_network_bridges]

  triggers_replace = [
    var.target_node
  ]

  provisioner "local-exec" {
    command = <<EOT
      # 1. Create SDN Zone 'internet' with dnsmasq DHCP engine
      curl -k -s -H "Authorization: PVEAPIToken=${var.proxmox_api_token}" \
        -X POST "${var.proxmox_endpoint}api2/json/cluster/sdn/zones" \
        -d "zone=internet&type=simple&dhcp=dnsmasq&ipam=pve" || true

      # 2. Create SDN VNet 'internet'
      curl -k -s -H "Authorization: PVEAPIToken=${var.proxmox_api_token}" \
        -X POST "${var.proxmox_endpoint}api2/json/cluster/sdn/vnets" \
        -d "vnet=internet&zone=internet&alias=internet" || true

      # 3. Trigger Proxmox SDN Reload (pvesdn reload)
      curl -k -s -H "Authorization: PVEAPIToken=${var.proxmox_api_token}" \
        -X PUT "${var.proxmox_endpoint}api2/json/cluster/sdn" || true
    EOT
  }
}
