output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.api_cluster.name
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.api_cluster.arn
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.api_service.name
}

output "service_arn" {
  description = "ARN of the ECS service"
  value       = aws_ecs_service.api_service.id
}

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = aws_lb.api_alb.dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = aws_lb.api_alb.zone_id
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.api_repository.repository_url
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.api_log_group.name
}
