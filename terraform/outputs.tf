output "frontend_lb_ip" {
  value       = module.load_balancer.load_balancer_ip
  description = "Consolidated load balancer external IP (frontend default)"
}

output "backend_lb_ip" {
  value       = module.load_balancer.load_balancer_ip
  description = "Consolidated load balancer external IP (routes /api/* to backend)"
}

output "mongodb_internal_ip" {
  value       = module.mongodb.mongodb_internal_ip
  description = "MongoDB VM internal IP (accessible from backend)"
}

output "artifact_registry_repository" {
  value       = module.artifacts.repository_id
  description = "Artifact Registry repository name"
}
