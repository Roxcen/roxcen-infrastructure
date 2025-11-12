output "api_endpoint" {
  description = "API endpoint URL"
  value       = "https://${var.domain_name}"
}

output "load_balancer_dns" {
  description = "Load balancer DNS name"
  value       = module.ecs_api.load_balancer_dns
}

output "cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs_api.cluster_name
}

output "service_name" {
  description = "ECS service name"
  value       = module.ecs_api.service_name
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.ecs_api.ecr_repository_url
}
