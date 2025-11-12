# Development Environment Configuration
aws_region = "ap-south-1"
environment = "dev"

# Project Configuration
project_name = "roxcen-hms-api"

# Domain Configuration  
domain_name = "dev-api.roxcen.com"

# VPC Configuration (use existing VPC or create new)
vpc_id = "vpc-xxxxxxxxxx"  # Replace with actual VPC ID
public_subnets = ["subnet-xxxxxxxxxx", "subnet-yyyyyyyyyy"]   # Replace with actual subnet IDs
private_subnets = ["subnet-xxxxxxxxxx", "subnet-yyyyyyyyyy"] # Replace with actual subnet IDs

# ECS Configuration (Development)
ecs_task_cpu = 512
ecs_task_memory = 1024
ecs_desired_count = 1

# SSL Configuration
ssl_certificate_arn = "arn:aws:acm:ap-south-1:ACCOUNT:certificate/cert-id"  # Replace with actual ARN

# Secrets Manager ARNs
database_url_secret_arn = "arn:aws:secretsmanager:ap-south-1:ACCOUNT:secret:dev-database-url"
redis_url_secret_arn = "arn:aws:secretsmanager:ap-south-1:ACCOUNT:secret:dev-redis-url"
jwt_secret_arn = "arn:aws:secretsmanager:ap-south-1:ACCOUNT:secret:jwt-secret-key"

# Development-specific tags
tags = {
  Environment = "development"
  Purpose = "api-hosting"
  Owner = "roxcen-dev-team"
  AutoShutdown = "true"
  BackupPolicy = "basic"
  MonitoringLevel = "standard"
}
