# Production Environment Configuration
aws_region  = "ap-south-1"
environment = "production"roduction Environment Configuration
aws_region = "ap-south-1"
environment = "prod"

# Project Configuration
project_name = "roxcen-hms-api"

# Domain Configuration
domain_name = "api.roxcen.com"

# VPC Configuration (use existing VPC or create new)
vpc_id = "vpc-xxxxxxxxxx"  # Replace with actual VPC ID
public_subnets = ["subnet-xxxxxxxxxx", "subnet-yyyyyyyyyy", "subnet-zzzzzzzzzz"]   # Replace with actual subnet IDs
private_subnets = ["subnet-xxxxxxxxxx", "subnet-yyyyyyyyyy", "subnet-zzzzzzzzzz"] # Replace with actual subnet IDs

# ECS Configuration (Production)
ecs_task_cpu = 1024
ecs_task_memory = 2048
ecs_desired_count = 2
ecs_min_capacity = 2
ecs_max_capacity = 10

# SSL Configuration
ssl_certificate_arn = "arn:aws:acm:ap-south-1:ACCOUNT:certificate/cert-id"  # Replace with actual ARN

# Secrets Manager ARNs
database_url_secret_arn = "arn:aws:secretsmanager:ap-south-1:ACCOUNT:secret:prod-database-url"
redis_url_secret_arn = "arn:aws:secretsmanager:ap-south-1:ACCOUNT:secret:prod-redis-url"
jwt_secret_arn = "arn:aws:secretsmanager:ap-south-1:ACCOUNT:secret:jwt-secret-key"

# Production-specific tags
tags = {
  Environment = "production"
  Purpose = "api-hosting"
  Owner = "roxcen-ops-team"
  AutoShutdown = "false"
  BackupPolicy = "comprehensive"
  MonitoringLevel = "critical"
  Compliance = "required"
}
