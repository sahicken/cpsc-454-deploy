terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket  = "${GCP_PROJECT_ID}-terraform-state"
    prefix  = "deploy"
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# Artifact Registry
module "artifacts" {
  source = "./modules/artifacts"

  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region
  repository_id  = "app-images"
}

# Network
module "network" {
  source = "./modules/network"

  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region
  network_name   = "app-network"
}

# MongoDB VM
module "mongodb" {
  source = "./modules/mongodb"

  gcp_project_id        = var.gcp_project_id
  gcp_region            = var.gcp_region
  machine_type          = var.mongodb_machine_type
  environment           = var.environment
  network_id            = module.network.network_id
  subnet_id             = module.network.subnet_id
  service_account_email = google_service_account.vm_sa.email
}

# Service Account for VMs
resource "google_service_account" "vm_sa" {
  account_id   = "app-vm-sa"
  display_name = "Service account for app VMs"
  project      = var.gcp_project_id
}

# IAM: allow VMs to pull images from Artifact Registry
resource "google_artifact_registry_repository_iam_member" "vm_pull_images" {
  location   = var.gcp_region
  repository = module.artifacts.repository_id
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.vm_sa.email}"
  project    = var.gcp_project_id
}

# IAM: allow VMs to access Secret Manager
resource "google_secret_manager_secret_iam_member" "vm_access_jwt_secret" {
  secret_id = "jwt-secret"
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.vm_sa.email}"
}

resource "google_secret_manager_secret_iam_member" "vm_access_mongo_user" {
  secret_id = "mongo-root-username"
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.vm_sa.email}"
}

resource "google_secret_manager_secret_iam_member" "vm_access_mongo_pass" {
  secret_id = "mongo-root-password"
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.vm_sa.email}"
}

# Frontend Compute (Managed Instance Group + LB)
module "frontend_compute" {
  source = "./modules/compute/instance_template"

  gcp_project_id        = var.gcp_project_id
  gcp_region            = var.gcp_region
  gcp_zone              = var.gcp_zone
  service_name          = "frontend"
  machine_type          = var.machine_type
  environment           = var.environment
  image_repository      = module.artifacts.repository_id
  service_account_email = google_service_account.vm_sa.email
  network_id            = module.network.network_id
  subnet_id             = module.network.subnet_id
  container_image       = "${var.gcp_region}-docker.pkg.dev/${var.gcp_project_id}/${module.artifacts.repository_id}/frontend:latest"
  container_port        = 3000
  health_check_path     = "/"
  health_check_port     = 3000
  min_replicas          = 1
  max_replicas          = 2
  create_load_balancer  = false
  use_zonal_mig         = var.use_zonal_mig

  depends_on = [module.artifacts, module.network]
}

# Backend Compute (Managed Instance Group + LB)
module "backend_compute" {
  source = "./modules/compute/instance_template"

  gcp_project_id        = var.gcp_project_id
  gcp_region            = var.gcp_region
  gcp_zone              = var.gcp_zone
  service_name          = "backend"
  machine_type          = var.machine_type
  environment           = var.environment
  image_repository      = module.artifacts.repository_id
  service_account_email = google_service_account.vm_sa.email
  network_id            = module.network.network_id
  subnet_id             = module.network.subnet_id
  container_image       = "${var.gcp_region}-docker.pkg.dev/${var.gcp_project_id}/${module.artifacts.repository_id}/backend:latest"
  container_port        = 9001
  health_check_path     = "/health"
  health_check_port     = 9001
  min_replicas          = 1
  max_replicas          = 2
  mongodb_host          = module.mongodb.mongodb_internal_ip
  mongodb_port          = 27017
  create_load_balancer  = false
  use_zonal_mig         = var.use_zonal_mig

  depends_on = [module.artifacts, module.network, module.mongodb]
}

# Consolidated HTTP(S) Load Balancer routing frontend default and /api/* to backend
module "load_balancer" {
  source = "./modules/loadbalancer"

  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region

  frontend_backend_service_id = module.frontend_compute.backend_service_id
  backend_backend_service_id  = module.backend_compute.backend_service_id
  name_prefix                 = "app-staging"

  depends_on = [module.frontend_compute, module.backend_compute]
}

output "load_balancer_ip" {
  value = module.load_balancer.load_balancer_ip
}
