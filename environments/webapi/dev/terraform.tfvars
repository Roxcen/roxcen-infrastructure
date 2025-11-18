# Development Environment Variables
environment    = "development"
project_name   = "roxcen-hms"
aws_region     = "ap-south-1"

# Domain Configuration
domain_name = "api-dev.roxcen.com"  # Development API subdomain
create_hosted_zone = true  # Set to false if you already have a hosted zone

# ECS Configuration
ecs_task_cpu       = 512
ecs_task_memory    = 1024
ecs_desired_count  = 1

# Secrets Configuration
jwt_secret_arn = "arn:aws:secretsmanager:ap-south-1:269010807913:secret:roxcen/development/jwt-secret-UX0PKK"

# Tags
tags = {
  Environment = "development"
  Project     = "roxcen-hms"
  Component   = "webapi"
  Owner       = "roxcen-team"
}
