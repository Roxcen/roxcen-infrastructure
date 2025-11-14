# Development Environment Configuration
aws_region  = "ap-south-1"
environment = "development"

# Project Configuration
project_name = "roxcen-hms-api"

# Domain Configuration  
domain_name = "dev-api.roxcen.com"

# VPC Configuration (using data sources from shared infrastructure)
# vpc_id, subnets, and database_url_secret_arn will be fetched from shared infrastructure
# No need to specify here - data sources will be used

# ECS Configuration (Development)
ecs_task_cpu      = 512
ecs_task_memory   = 1024
ecs_desired_count = 1

# SSL Configuration (disabled for testing - certificate needs DNS validation)
ssl_certificate_arn = ""

# Secrets Manager ARNs (using direct ARNs instead of shared infrastructure)
# Redis removed for cost optimization - will use AWS SQS for background tasks when needed  
jwt_secret_arn = "arn:aws:secretsmanager:ap-south-1:269010807913:secret:roxcen/development/jwt-secret-UX0PKK"

# Development-specific tags
tags = {
  Environment     = "development"
  Purpose         = "api-hosting"
  Owner           = "roxcen-dev-team"
  AutoShutdown    = "true"
  BackupPolicy    = "basic"
  MonitoringLevel = "standard"
}
