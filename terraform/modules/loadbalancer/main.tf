terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

resource "google_compute_url_map" "lb" {
  name            = "${var.name_prefix}-url-map"
  default_service = var.frontend_backend_service_id

  host_rule {
    hosts        = ["*"]
    path_matcher = "app-matcher"
  }

  path_matcher {
    name            = "app-matcher"
    default_service = var.frontend_backend_service_id

    path_rule {
      paths   = ["/api/*"]
      service = var.backend_backend_service_id
    }
  }
}

resource "google_compute_target_http_proxy" "lb" {
  name    = "${var.name_prefix}-http-proxy"
  url_map = google_compute_url_map.lb.id
}

resource "google_compute_global_forwarding_rule" "lb" {
  name                  = "${var.name_prefix}-forwarding-rule"
  load_balancing_scheme = "EXTERNAL"
  ip_protocol           = "TCP"
  port_range            = "80"
  target                = google_compute_target_http_proxy.lb.id
}

output "load_balancer_ip" {
  value = google_compute_global_forwarding_rule.lb.ip_address
}
