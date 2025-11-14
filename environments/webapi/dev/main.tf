# Development Environment Main Configuration

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Get shared infrastructure state
data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket = "roxcen-terraform-state"
    key    = "shared/terraform.tfstate"
    region = "ap-south-1"
  }
}

# ECS + API Module for Development
module "ecs_api" {
  source = "../../../modules/ecs-api"

  environment = var.environment

  # VPC Configuration from shared infrastructure
  vpc_id          = data.terraform_remote_state.shared.outputs.vpc_id
  public_subnets  = data.terraform_remote_state.shared.outputs.public_subnet_ids
  private_subnets = data.terraform_remote_state.shared.outputs.private_subnet_ids

  # Load Balancer
  ssl_certificate_arn = var.ssl_certificate_arn
  domain_name         = var.domain_name

  # Database Configuration
  database_url_secret_arn = "arn:aws:secretsmanager:ap-south-1:269010807913:secret:roxcen/development/database-url-5IRWLW"
  jwt_secret_arn          = var.jwt_secret_arn
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
  alarm_actions       = [] # No critical alerts for dev

  dimensions = {
    ServiceName = module.ecs_api.service_name
    ClusterName = module.ecs_api.cluster_name
  }

  tags = var.tags
}
