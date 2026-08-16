# Cloud Storage (GCS) Bucket for Datasets and Model Artifacts

resource "google_storage_bucket" "research_data" {
  name          = "${var.project_id}-datasets"
  location      = var.region
  force_destroy = false

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  depends_on = [google_project_service.research_services]
}
