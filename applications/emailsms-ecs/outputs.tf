output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.emailsms.repository_url
}

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = aws_lb.emailsms.dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = aws_lb.emailsms.zone_id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.emailsms.name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.emailsms.name
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.app_logs.name
}

output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = aws_ecs_task_definition.emailsms.arn
}

output "service_url" {
  description = "Service URL"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "http://${aws_lb.emailsms.dns_name}"
}
