terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# MongoDB VM Instance Template
resource "google_compute_instance_template" "mongodb" {
  name_prefix = "mongodb-template-"
  description = "Instance template for MongoDB service"

  machine_type = var.machine_type

  disk {
    source_image = "cos-cloud/cos-stable"
    disk_size_gb = 50
    boot         = true
  }

  network_interface {
    network    = var.network_id
    subnetwork = var.subnet_id

    access_config {
      # External IP for access/debugging
    }
  }

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  metadata = {
    "gce-container-declaration" = jsonencode({
      spec = {
        containers = [
          {
            image = "mongo:8.0"
            ports = [
              {
                containerPort = 27017
              }
            ]
            env = [
              {
                name  = "MONGO_INITDB_ROOT_USERNAME"
                value = "admin"
              },
              {
                name  = "MONGO_INITDB_ROOT_PASSWORD"
                value = "changeme"  # Override with Secret Manager in production
              }
            ]
            volumeMounts = [
              {
                name      = "mongodb-data"
                mountPath = "/data/db"
              }
            ]
          }
        ]
        volumes = [
          {
            name = "mongodb-data"
            emptyDir = {}
          }
        ]
        restartPolicy = "Always"
      }
    })
    "enable-oslogin" = "TRUE"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = ["mongodb-vm"]
}

# MongoDB VM Instance
resource "google_compute_instance_from_template" "mongodb" {
  name             = "mongodb-${var.environment}"
  zone             = "${var.gcp_region}-a"
  source_instance_template = google_compute_instance_template.mongodb.id
}

# Firewall rule for MongoDB access from backend
resource "google_compute_firewall" "mongodb" {
  name    = "mongodb-allow-from-backend"
  network = var.network_id

  allow {
    protocol = "tcp"
    ports    = ["27017"]
  }

  source_tags = ["backend-vm"]
  target_tags = ["mongodb-vm"]
}

output "mongodb_internal_ip" {
  value = google_compute_instance_from_template.mongodb.network_interface[0].network_ip
}

output "mongodb_external_ip" {
  value = google_compute_instance_from_template.mongodb.network_interface[0].access_config[0].nat_ip
}

variable "gcp_project_id" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "machine_type" {
  type = string
}

variable "environment" {
  type = string
}

variable "network_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "service_account_email" {
  type = string
}
