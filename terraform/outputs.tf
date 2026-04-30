output "frontend_lb_ip" {
  value       = module.frontend_compute.load_balancer_ip
  description = "Frontend load balancer external IP"
}

output "backend_lb_ip" {
  value       = module.backend_compute.load_balancer_ip
  description = "Backend load balancer external IP"
}

output "mongodb_internal_ip" {
  value       = module.mongodb.mongodb_internal_ip
  description = "MongoDB VM internal IP (accessible from backend)"
}

output "artifact_registry_repository" {
  value       = module.artifacts.repository_id
  description = "Artifact Registry repository name"
}
