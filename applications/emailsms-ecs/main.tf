# EmailSMS Microservice Infrastructure
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket = "roxcen-terraform-state"
    key    = "applications/emailsms/terraform.tfstate"
    region = "ap-south-1"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "Roxcen"
      Service     = "EmailSMS"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}

# Data sources for shared infrastructure
data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket = "roxcen-terraform-state"
    key    = "shared/terraform.tfstate"
    region = "ap-south-1"
  }
}

locals {
  name_prefix = "${var.project_name}-emailsms-${var.environment}"
  
  # Common tags
  common_tags = {
    Project     = var.project_name
    Service     = "EmailSMS"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
  
  # Shared VPC data
  vpc_id             = data.terraform_remote_state.shared.outputs.vpc_id
  private_subnet_ids = data.terraform_remote_state.shared.outputs.private_subnet_ids
  public_subnet_ids  = data.terraform_remote_state.shared.outputs.public_subnet_ids
  
  # Environment-specific configurations
  cpu_memory_configs = {
    development = {
      cpu    = 256
      memory = 512
      desired_count = 1
      min_capacity  = 1
      max_capacity  = 2
    }
    production = {
      cpu    = 512
      memory = 1024
      desired_count = 2
      min_capacity  = 2
      max_capacity  = 10
    }
  }
  
  config = local.cpu_memory_configs[var.environment]
}

# ECR Repository
resource "aws_ecr_repository" "emailsms" {
  name                 = "${var.project_name}-emailsms"
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
  
  encryption_configuration {
    encryption_type = "AES256"
  }
  
  lifecycle_policy {
    policy = jsonencode({
      rules = [
        {
          rulePriority = 1
          description  = "Keep last 10 images"
          selection = {
            tagStatus     = "tagged"
            tagPrefixList = ["v", "release", "dev"]
            countType     = "imageCountMoreThan"
            countNumber   = 10
          }
          action = {
            type = "expire"
          }
        },
        {
          rulePriority = 2
          description  = "Delete untagged images older than 1 day"
          selection = {
            tagStatus   = "untagged"
            countType   = "sinceImagePushed"
            countUnit   = "days"
            countNumber = 1
          }
          action = {
            type = "expire"
          }
        }
      ]
    })
  }
  
  tags = local.common_tags
}

# ECS Cluster
resource "aws_ecs_cluster" "emailsms" {
  name = local.name_prefix
  
  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      
      log_configuration {
        cloud_watch_encryption_enabled = false
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ecs_logs.name
      }
    }
  }
  
  tags = local.common_tags
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${local.name_prefix}"
  retention_in_days = var.environment == "production" ? 30 : 7
  
  tags = local.common_tags
}

# CloudWatch Log Group for Application
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ecs/${local.name_prefix}/app"
  retention_in_days = var.environment == "production" ? 30 : 7
  
  tags = local.common_tags
}

# Security Group for ECS Tasks
resource "aws_security_group" "ecs_tasks" {
  name_prefix = "${local.name_prefix}-ecs-tasks"
  vpc_id      = local.vpc_id
  
  ingress {
    from_port       = 9000
    to_port         = 9000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "HTTP from ALB"
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ecs-tasks"
  })
}

# Security Group for ALB
resource "aws_security_group" "alb" {
  name_prefix = "${local.name_prefix}-alb"
  vpc_id      = local.vpc_id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb"
  })
}

# Application Load Balancer
resource "aws_lb" "emailsms" {
  name               = "${substr(local.name_prefix, 0, 32)}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = local.public_subnet_ids
  
  enable_deletion_protection = var.environment == "production" ? true : false
  
  tags = local.common_tags
}

# ALB Target Group
resource "aws_lb_target_group" "emailsms" {
  name        = "${substr(local.name_prefix, 0, 32)}"
  port        = 9000
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip"
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
  
  tags = local.common_tags
}

# ALB Listener (HTTP)
resource "aws_lb_listener" "emailsms_http" {
  load_balancer_arn = aws_lb.emailsms.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ALB Listener (HTTPS) - Will need SSL certificate
resource "aws_lb_listener" "emailsms_https" {
  count             = var.ssl_certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.emailsms.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.ssl_certificate_arn
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.emailsms.arn
  }
}

# ALB Listener for HTTP when no SSL (development)
resource "aws_lb_listener" "emailsms_http_direct" {
  count             = var.ssl_certificate_arn == "" ? 1 : 0
  load_balancer_arn = aws_lb.emailsms.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.emailsms.arn
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "emailsms" {
  family                   = local.name_prefix
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = local.config.cpu
  memory                   = local.config.memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn
  
  container_definitions = jsonencode([
    {
      name  = "emailsms"
      image = "${aws_ecr_repository.emailsms.repository_url}:latest"
      
      essential = true
      
      portMappings = [
        {
          containerPort = 9000
          hostPort      = 9000
          protocol      = "tcp"
        }
      ]
      
      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "DATABASE_URL"
          value = var.database_url
        },
        {
          name  = "REDIS_URL" 
          value = var.redis_url
        }
      ]
      
      secrets = [
        {
          name      = "SENDGRID_API_KEY"
          valueFrom = var.sendgrid_secret_arn
        },
        {
          name      = "TWILIO_ACCOUNT_SID"
          valueFrom = var.twilio_sid_secret_arn
        },
        {
          name      = "TWILIO_AUTH_TOKEN"
          valueFrom = var.twilio_token_secret_arn
        },
        {
          name      = "JWT_SECRET_KEY"
          valueFrom = var.jwt_secret_arn
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app_logs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
      
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:9000/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])
  
  tags = local.common_tags
}

# ECS Service
resource "aws_ecs_service" "emailsms" {
  name            = local.name_prefix
  cluster         = aws_ecs_cluster.emailsms.id
  task_definition = aws_ecs_task_definition.emailsms.arn
  desired_count   = local.config.desired_count
  launch_type     = "FARGATE"
  
  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = local.private_subnet_ids
    assign_public_ip = false
  }
  
  load_balancer {
    target_group_arn = aws_lb_target_group.emailsms.arn
    container_name   = "emailsms"
    container_port   = 9000
  }
  
  depends_on = [
    aws_lb_listener.emailsms_http,
    aws_lb_listener.emailsms_https,
    aws_lb_listener.emailsms_http_direct
  ]
  
  tags = local.common_tags
}

# Auto Scaling Target
resource "aws_appautoscaling_target" "emailsms" {
  max_capacity       = local.config.max_capacity
  min_capacity       = local.config.min_capacity
  resource_id        = "service/${aws_ecs_cluster.emailsms.name}/${aws_ecs_service.emailsms.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  
  tags = local.common_tags
}

# Auto Scaling Policy - CPU
resource "aws_appautoscaling_policy" "emailsms_cpu" {
  name               = "${local.name_prefix}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.emailsms.resource_id
  scalable_dimension = aws_appautoscaling_target.emailsms.scalable_dimension
  service_namespace  = aws_appautoscaling_target.emailsms.service_namespace
  
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

# Auto Scaling Policy - Memory
resource "aws_appautoscaling_policy" "emailsms_memory" {
  name               = "${local.name_prefix}-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.emailsms.resource_id
  scalable_dimension = aws_appautoscaling_target.emailsms.scalable_dimension
  service_namespace  = aws_appautoscaling_target.emailsms.service_namespace
  
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 80.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

# IAM Role for ECS Execution
resource "aws_iam_role" "ecs_execution_role" {
  name = "${local.name_prefix}-ecs-execution-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  
  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Additional policy for Secrets Manager access
resource "aws_iam_role_policy" "ecs_execution_secrets" {
  name = "${local.name_prefix}-ecs-execution-secrets"
  role = aws_iam_role.ecs_execution_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          var.sendgrid_secret_arn,
          var.twilio_sid_secret_arn,
          var.twilio_token_secret_arn,
          var.jwt_secret_arn
        ]
      }
    ]
  })
}

# IAM Role for ECS Task
resource "aws_iam_role" "ecs_task_role" {
  name = "${local.name_prefix}-ecs-task-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  
  tags = local.common_tags
}

# Task role policy for application permissions
resource "aws_iam_role_policy" "ecs_task_policy" {
  name = "${local.name_prefix}-ecs-task-policy"
  role = aws_iam_role.ecs_task_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}
