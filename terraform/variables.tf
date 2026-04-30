variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "YOUR_GCP_PROJECT_ID"  # Replace or use TF_VAR_gcp_project_id env var
}

variable "gcp_region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Deployment environment (staging or prod)"
  type        = string
  default     = "staging"
}

variable "machine_type" {
  description = "GCE machine type for frontend and backend"
  type        = string
  default     = "e2-micro"
}

variable "mongodb_machine_type" {
  description = "GCE machine type for MongoDB (staging default; override for prod if needed)"
  type        = string
  default     = "e2-micro"
}

variable "use_zonal_mig" {
  description = "Use zonal MIG for staging (simpler), regional for prod (HA)"
  type        = bool
  default     = true  # Zonal for staging
}

variable "gcp_zone" {
  description = "GCP Zone for zonal deployments"
  type        = string
  default     = "us-central1-a"
}
