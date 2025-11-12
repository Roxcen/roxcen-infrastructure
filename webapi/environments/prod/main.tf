# Production Environment Main Configuration

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ECS + API Module for Production
module "ecs_api" {
  source = "../../modules/ecs-api"

  environment = var.environment
  project_name = var.project_name
  
  # VPC Configuration
  vpc_id = var.vpc_id
  public_subnets = var.public_subnets
  private_subnets = var.private_subnets
  
  # ECS Configuration (Production optimized)
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

# Production CloudWatch Alarms (Critical)
resource "aws_cloudwatch_metric_alarm" "prod_high_cpu" {
  alarm_name          = "prod-api-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "70"  # Lower threshold for production
  alarm_description   = "CRITICAL: High CPU usage in production API"
  
  # Production should have SNS topic for alerts
  alarm_actions = [aws_sns_topic.prod_alerts.arn]
  ok_actions    = [aws_sns_topic.prod_alerts.arn]

  dimensions = {
    ServiceName = module.ecs_api.service_name
    ClusterName = module.ecs_api.cluster_name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "prod_high_memory" {
  alarm_name          = "prod-api-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "CRITICAL: High memory usage in production API"
  
  alarm_actions = [aws_sns_topic.prod_alerts.arn]

  dimensions = {
    ServiceName = module.ecs_api.service_name
    ClusterName = module.ecs_api.cluster_name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "prod_service_count" {
  alarm_name          = "prod-api-service-count"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "RunningTaskCount"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.ecs_desired_count
  alarm_description   = "CRITICAL: API service running task count below desired"
  
  alarm_actions = [aws_sns_topic.prod_alerts.arn]

  dimensions = {
    ServiceName = module.ecs_api.service_name
    ClusterName = module.ecs_api.cluster_name
  }

  tags = var.tags
}

# SNS Topic for Production Alerts
resource "aws_sns_topic" "prod_alerts" {
  name = "roxcen-api-prod-alerts"

  tags = merge(var.tags, {
    Purpose = "production-alerts"
  })
}

# Auto Scaling for Production
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = var.ecs_max_capacity
  min_capacity       = var.ecs_min_capacity
  resource_id        = "service/${module.ecs_api.cluster_name}/${module.ecs_api.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "scale_up" {
  name               = "scale-up"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

resource "aws_appautoscaling_policy" "scale_down" {
  name               = "scale-down"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 80.0
  }
}
