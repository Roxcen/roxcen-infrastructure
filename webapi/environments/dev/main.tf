# Development Environment Main Configuration

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ECS + API Module for Development
module "ecs_api" {
  source = "../../modules/ecs-api"

  environment = var.environment
  project_name = var.project_name
  
  # VPC Configuration
  vpc_id = var.vpc_id
  public_subnets = var.public_subnets
  private_subnets = var.private_subnets
  
  # ECS Configuration (Development optimized)
  ecs_task_cpu = var.ecs_task_cpu
  ecs_task_memory = var.ecs_task_memory
  ecs_desired_count = var.ecs_desired_count
  
  # Load Balancer
  ssl_certificate_arn = var.ssl_certificate_arn
  domain_name = var.domain_name
  
  # Database Configuration
  database_url_secret_arn = var.database_url_secret_arn
  redis_url_secret_arn = var.redis_url_secret_arn
  jwt_secret_arn = var.jwt_secret_arn
  
  tags = merge(var.tags, {
    Environment = var.environment
  })
}

# Development-specific CloudWatch alarms (non-critical)
resource "aws_cloudwatch_metric_alarm" "dev_high_cpu" {
  alarm_name          = "dev-api-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "High CPU usage in dev API environment"
  alarm_actions       = []  # No critical alerts for dev

  dimensions = {
    ServiceName = module.ecs_api.service_name
    ClusterName = module.ecs_api.cluster_name
  }

  tags = var.tags
}
