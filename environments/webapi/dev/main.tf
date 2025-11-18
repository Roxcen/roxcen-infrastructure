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

# SSL Certificate and Route53 Setup
module "ssl_certificate" {
  source = "../../../modules/ssl-certificate"

  domain_name         = var.domain_name
  environment         = var.environment
  create_hosted_zone  = var.create_hosted_zone
  existing_hosted_zone_id = var.existing_hosted_zone_id
}

# ECS + API Module for Development
module "ecs_api" {
  source = "../../../modules/ecs-api"

  environment = var.environment

  # VPC Configuration from shared infrastructure
  vpc_id          = data.terraform_remote_state.shared.outputs.vpc_id
  public_subnets  = data.terraform_remote_state.shared.outputs.public_subnet_ids
  private_subnets = data.terraform_remote_state.shared.outputs.private_subnet_ids

  # SSL and Domain Configuration
  ssl_certificate_arn = module.ssl_certificate.certificate_arn
  domain_name         = var.domain_name
  hosted_zone_id      = module.ssl_certificate.hosted_zone_id

  # Database Configuration
  database_url_secret_arn = "arn:aws:secretsmanager:ap-south-1:269010807913:secret:roxcen/development/database-url-5IRWLW"
  jwt_secret_arn          = var.jwt_secret_arn

  depends_on = [module.ssl_certificate]
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
