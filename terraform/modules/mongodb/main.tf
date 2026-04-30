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
    disk_size_gb = 100  # Larger boot disk for MongoDB staging data
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
    # Use startup-script to fetch secrets from Secret Manager at boot,
    # then run the MongoDB container with those secrets. This avoids
    # placing secret values into Terraform state or instance metadata.
    "startup-script" = <<'EOT'
#!/bin/bash
set -euo pipefail

# Ensure data directory
MOUNT_POINT="/data/db"
mkdir -p "${MOUNT_POINT}"
chmod 700 "${MOUNT_POINT}"

# Get project id from metadata
PROJECT_ID=$(curl -s -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/project/project-id")

# Get access token for the VM service account
TOKEN=$(curl -s -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token" | sed -n 's/.*"access_token":"\([^\"]*\)".*/\1/p')

# Helper to read secret payload (base64) and decode
read_secret() {
  local name="$1"
  local data_b64
  data_b64=$(curl -s -H "Authorization: Bearer ${TOKEN}" "https://secretmanager.googleapis.com/v1/projects/${PROJECT_ID}/secrets/${name}/versions/latest:access" | sed -n 's/.*"data":"\([^\"]*\)".*/\1/p')
  echo "${data_b64}" | base64 --decode
}

MONGO_USER=$(read_secret "mongo-root-username") || exit 1
MONGO_PASS=$(read_secret "mongo-root-password") || exit 1

# Pull and run MongoDB container (use host path for data)
container_image="mongo:8.0"
if command -v docker >/dev/null 2>&1; then
  docker pull "${container_image}"
  docker rm -f mongodb || true
  docker run -d --name mongodb \
    -p 27017:27017 \
    -v ${MOUNT_POINT}:/data/db \
    -e MONGO_INITDB_ROOT_USERNAME="${MONGO_USER}" \
    -e MONGO_INITDB_ROOT_PASSWORD="${MONGO_PASS}" \
    --restart unless-stopped \
    "${container_image}"
else
  # Try containerd ctr as fallback
  if command -v crictl >/dev/null 2>&1; then
    # crictl may not support docker run style; skip and let COS run containers
    echo "docker not available; please ensure container runtime is present"
    exit 1
  else
    echo "No container runtime found; exiting"
    exit 1
  fi
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

## Note: secrets are fetched on VM boot using the VM service account.
