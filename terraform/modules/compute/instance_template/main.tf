terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Instance Template
resource "google_compute_instance_template" "app" {
  name_prefix = "${var.service_name}-template-"
  description = "Instance template for ${var.service_name} service"

  machine_type = var.machine_type

  disk {
    source_image = "cos-cloud/cos-stable"
    disk_size_gb = 20
    boot         = true
  }

  network_interface {
    network    = var.network_id
    subnetwork = var.subnet_id

    access_config {
      # External IP for outbound access
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
            image = var.container_image
            ports = [
              {
                containerPort = var.container_port
              }
            ]
            env = concat(
              [
                {
                  name  = "ENVIRONMENT"
                  value = var.environment
                }
              ],
              var.service_name == "backend" ? [
                {
                  name  = "MONGODB_HOST"
                  value = var.mongodb_host
                },
                {
                  name  = "MONGODB_PORT"
                  value = tostring(var.mongodb_port)
                }
              ] : [],
              var.service_name == "frontend" ? [
                {
                  name  = "NEXT_PUBLIC_API_BASE_URL"
                  value = "http://${var.backend_lb_ip}:9001"
                }
              ] : []
            )
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

  tags = ["${var.service_name}-vm"]
}

# Health Check
resource "google_compute_health_check" "app" {
  name = "${var.service_name}-health-check"

  http_health_check {
    port         = var.health_check_port
    request_path = var.health_check_path
  }

  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2
}

# Backend Service
resource "google_compute_backend_service" "app" {
  name                  = "${var.service_name}-backend-service"
  load_balancing_scheme = "EXTERNAL"
  protocol              = "HTTP"
  port_name             = "http"
  health_checks         = [google_compute_health_check.app.id]

  backend {
    group          = google_compute_region_instance_group_manager.app.instance_group
    balancing_mode = "RATE"
    max_rate       = 100
  }
}

# Managed Instance Group
resource "google_compute_region_instance_group_manager" "app" {
  name   = "${var.service_name}-mig"
  region = var.gcp_region

  version {
    instance_template = google_compute_instance_template.app.id
    name              = "primary"
  }

  target_size = var.min_replicas

  named_port {
    name = "http"
    port = var.container_port
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.app.id
    initial_delay_sec = 60
  }

  update_policy {
    instance_redistribution_type = "PROACTIVE"
    max_surge_fixed              = 1
    max_unavailable_fixed        = 0
    min_ready_sec                = 60
    replacement_method           = "SUBSTITUTE"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Firewall Rule
resource "google_compute_firewall" "app" {
  name    = "${var.service_name}-allow-http"
  network = var.network_id

  allow {
    protocol = "tcp"
    ports    = [var.container_port]
  }

  target_tags = ["${var.service_name}-vm"]
}

# HTTP Load Balancer
resource "google_compute_url_map" "app" {
  name            = "${var.service_name}-url-map"
  default_service = google_compute_backend_service.app.id
}

resource "google_compute_target_http_proxy" "app" {
  name            = "${var.service_name}-http-proxy"
  url_map         = google_compute_url_map.app.id
}

resource "google_compute_global_forwarding_rule" "app" {
  name                  = "${var.service_name}-forwarding-rule"
  load_balancing_scheme = "EXTERNAL"
  ip_protocol           = "TCP"
  port_range            = "80"
  target                = google_compute_target_http_proxy.app.id
}

output "load_balancer_ip" {
  value = google_compute_global_forwarding_rule.app.ip_address
}
