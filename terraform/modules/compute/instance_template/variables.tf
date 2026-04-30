variable "gcp_project_id" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "service_name" {
  type = string
}

variable "machine_type" {
  type = string
}

variable "environment" {
  type = string
}

variable "image_repository" {
  type = string
}

variable "service_account_email" {
  type = string
}

variable "network_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "container_image" {
  type = string
}

variable "container_port" {
  type = number
}

variable "health_check_path" {
  type = string
}

variable "health_check_port" {
  type = number
}

variable "min_replicas" {
  type = number
}

variable "max_replicas" {
  type = number
}

variable "mongodb_host" {
  type    = string
  default = ""
}

variable "mongodb_port" {
  type    = number
  default = 27017
}

variable "backend_lb_ip" {
  type    = string
  default = ""
}

variable "create_load_balancer" {
  type    = bool
  default = true
}

variable "source_ranges" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "use_zonal_mig" {
  description = "Use zonal MIG (staging) vs regional MIG (prod HA)"
  type        = bool
  default     = true
}

variable "gcp_zone" {
  description = "GCP Zone for zonal deployments"
  type        = string
  default     = "us-central1-a"
}
