# ==========================================================
# 📡 Automated Management VM Peer Enrollment (Peer #1)
# ==========================================================
# Automatically deploys the netbird-client container on the
# Management VM and joins it to the mesh in group 'servers'.
# Upgrades are automatically detected and applied via Terraform!
# ==========================================================

resource "terraform_data" "enroll_mgmt_vm_peer" {
  depends_on = [
    google_secret_manager_secret_version.netbird_setup_key_version,
    netbird_setup_key.servers,
    netbird_policy.servers_mesh,
    netbird_policy.sysadmin_access,
  ]

  # 🔍 Automatically triggers redeployment when setup key or client version changes!
  triggers_replace = [
    netbird_setup_key.servers.id,
    var.netbird_client_version,
  ]

  provisioner "local-exec" {
    command = <<-EOT
      echo "==> 📡 Enrolling Management VM into NetBird Mesh (Version: ${var.netbird_client_version})..."
      gcloud compute ssh brainlab-mgmt-vm \
        --project="${var.project_id}" \
        --zone="${var.zone}" \
        --tunnel-through-iap \
        --command="
          sudo mkdir -p /opt/brainlab/netbird/client
          sudo docker rm -f netbird-client 2>/dev/null || true
          sudo docker run -d \
            --name netbird-client \
            --restart unless-stopped \
            --network host \
            --cap-add NET_ADMIN \
            --cap-add SYS_MODULE \
            -v /dev/net/tun:/dev/net/tun \
            -v /opt/brainlab/netbird/client:/etc/netbird \
            -e TZ=Asia/Bangkok \
            -e NB_MANAGEMENT_URL='${var.netbird_management_url}' \
            -e NB_SETUP_KEY='${netbird_setup_key.servers.key}' \
            netbirdio/netbird:${var.netbird_client_version}

          echo '==> ⏳ Waiting for wt0 WireGuard interface to establish...'
          for i in \$(seq 1 30); do
            if ip addr show wt0 >/dev/null 2>&1; then
              echo '==> ✅ wt0 WireGuard Interface is LIVE!'
              ip -4 addr show wt0
              sudo docker exec netbird-client netbird status || true
              exit 0
            fi
            sleep 1
          done
          echo '⚠️ Warning: wt0 did not appear within 30s'
        "
    EOT
  }
}
