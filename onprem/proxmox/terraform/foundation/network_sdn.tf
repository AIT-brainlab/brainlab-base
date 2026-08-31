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
      # Configure vmbr1 (Frontend 10G High-Speed Port enp2s0)
      curl -k -s -H "Authorization: PVEAPIToken=${var.proxmox_api_token}" \
        -X POST "${var.proxmox_endpoint}api2/json/nodes/${var.target_node}/network" \
        -d "iface=vmbr1&type=bridge&autostart=1&bridge_ports=enp2s0&comments=Frontend%2010G%20High-Speed%20Port" || true
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

      # 3. Configure Subnet 10.10.20.0/24 with 10G Egress SNAT to 192.41.170.39
      curl -k -s -H "Authorization: PVEAPIToken=${var.proxmox_api_token}" \
        -X POST "${var.proxmox_endpoint}api2/json/cluster/sdn/vnets/internet/subnets" \
        -d "type=subnet&subnet=internet-10.10.20.0-24&vnet=internet&network=10.10.20.0/24&gateway=10.10.20.1&snat=1" || true

      # 4. Trigger Proxmox SDN Reload (pvesdn reload)
      curl -k -s -H "Authorization: PVEAPIToken=${var.proxmox_api_token}" \
        -X PUT "${var.proxmox_endpoint}api2/json/cluster/sdn" || true
    EOT
  }
}
