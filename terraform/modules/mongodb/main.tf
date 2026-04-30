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

  # Attach a separate persistent disk (created below) to persist MongoDB data
  disk {
    auto_delete = false
    boot        = false
    source      = google_compute_disk.mongodb_disk.self_link
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
            hostPath = {
              path = "/data/db"
            }
          }
        ]
        restartPolicy = "Always"
      }
    })
    # Startup script mounts the persistent disk to /data/db before the container starts
    "startup-script" = <<EOT
#!/bin/bash
set -e
DISK_DEVICE="/dev/disk/by-id/google-mongodb-disk-${var.environment}"
MOUNT_POINT="/data/db"
mkdir -p $${MOUNT_POINT}
# wait for disk to be attached
for i in {1..30}; do
  if [ -e "$${DISK_DEVICE}" ]; then
    break
  fi
  sleep 1
done
if ! mountpoint -q $${MOUNT_POINT}; then
  # try to format if no filesystem
  if ! blkid $${DISK_DEVICE}; then
    mkfs.ext4 -F $${DISK_DEVICE} || true
  fi
  mount $${DISK_DEVICE} $${MOUNT_POINT}
  chown -R 1000:1000 $${MOUNT_POINT} || true
fi
EOT
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

# Persistent disk for MongoDB data
resource "google_compute_disk" "mongodb_disk" {
  name  = "mongodb-disk-${var.environment}"
  type  = "pd-standard"
  zone  = "${var.gcp_region}-a"
  size  = var.disk_size_gb
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

variable "disk_size_gb" {
  type    = number
  default = 50
}
