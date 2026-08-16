# GPU Compute Instance Template (Spot VM for maximum credit efficiency)

resource "google_compute_instance" "research_gpu_vm" {
  count        = var.create_gpu_instance ? 1 : 0
  name         = "gpu-trainer-${var.researcher_name}"
  machine_type = var.machine_type
  zone         = var.zone

  scheduling {
    preemptible       = var.use_spot_vm
    automatic_restart = var.use_spot_vm ? false : true
    provisioning_model = var.use_spot_vm ? "SPOT" : "STANDARD"
  }

  guest_accelerator {
    type  = var.gpu_type
    count = var.gpu_count
  }

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 100 # GB
      type  = "pd-balanced"
    }
  }

  network_interface {
    network = "default"
    access_config {
      # Ephemeral public IP
    }
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e
    # Automated NVIDIA Driver & CUDA Setup for Ubuntu 22.04
    apt-get update
    apt-get install -y ubuntu-drivers-common
    ubuntu-drivers install --gpgpu
    systemctl restart systemd-timesyncd
  EOF

  tags = ["brainlab-research", "gpu-node"]

  service_account {
    scopes = ["cloud-platform"]
  }

  depends_on = [google_project_service.research_services]
}
