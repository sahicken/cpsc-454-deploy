terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

resource "google_compute_network" "app" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "app" {
  name          = "${var.network_name}-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.gcp_region
  network       = google_compute_network.app.id
}

output "network_id" {
  value = google_compute_network.app.id
}

output "subnet_id" {
  value = google_compute_subnetwork.app.id
}

variable "gcp_project_id" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "network_name" {
  type = string
}
