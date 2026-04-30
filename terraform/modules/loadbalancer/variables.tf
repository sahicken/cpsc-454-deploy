variable "gcp_project_id" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "frontend_backend_service_id" {
  type = string
}

variable "backend_backend_service_id" {
  type = string
}

variable "name_prefix" {
  type    = string
  default = "app"
}
