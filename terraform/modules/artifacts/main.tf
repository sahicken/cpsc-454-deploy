terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

resource "google_artifact_registry_repository" "app" {
  repository_id = var.repository_id
  format        = "DOCKER"
  location      = var.gcp_region
}

output "repository_id" {
  value = google_artifact_registry_repository.app.repository_id
}

output "repository_url" {
  value = "${var.gcp_region}-docker.pkg.dev/${var.gcp_project_id}/${google_artifact_registry_repository.app.repository_id}"
}

variable "gcp_project_id" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "repository_id" {
  type = string
}
