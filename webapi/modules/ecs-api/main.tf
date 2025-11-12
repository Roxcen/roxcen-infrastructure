# ECS Cluster
resource "aws_ecs_cluster" "api_cluster" {
  name = "roxcen-hms-api-cluster"
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  
  tags = {
    Environment = var.environment
    Project     = "roxcen-hms"
    Component   = "api"
  }
}

# ECR Repository
resource "aws_ecr_repository" "api_repository" {
  name = "roxcen-hms-api"
  
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
  
  lifecycle_policy {
    policy = jsonencode({
      rules = [
        {
          rulePriority = 1
          description  = "Keep last 30 release images"
          selection = {
            tagStatus     = "tagged"
            tagPrefixList = ["release-"]
            countType     = "imageCountMoreThan"
            countNumber   = 30
          }
          action = {
            type = "expire"
          }
        }
      ]
    })
  }
  
  tags = {
    Environment = var.environment
    Project     = "roxcen-hms"
    Component   = "api"
  }
}

# Application Load Balancer
resource "aws_lb" "api_alb" {
  name               = "roxcen-hms-api-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnets
  
  enable_deletion_protection = var.environment == "production"
  
  tags = {
    Environment = var.environment
    Project     = "roxcen-hms"
    Component   = "api-alb"
  }
}

# ALB Target Group
resource "aws_lb_target_group" "api_tg" {
  name     = "roxcen-hms-api-${var.environment}-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = var.vpc_id
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
    unhealthy_threshold = 5
  }
  
  tags = {
    Environment = var.environment
    Project     = "roxcen-hms"
    Component   = "api-tg"
  }
}

# ALB Listener
resource "aws_lb_listener" "api_listener" {
  load_balancer_arn = aws_lb.api_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.ssl_certificate_arn
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_tg.arn
  }
}

# ALB Listener for HTTP (redirect to HTTPS)
resource "aws_lb_listener" "api_listener_http" {
  load_balancer_arn = aws_lb.api_alb.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type = "redirect"
    
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "api_task" {
  family                   = "roxcen-hms-api-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.environment == "production" ? 1024 : 512
  memory                   = var.environment == "production" ? 2048 : 1024
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn
  
  container_definitions = jsonencode([
    {
      name  = "roxcen-hms-api"
      image = "${aws_ecr_repository.api_repository.repository_url}:latest"
      
      portMappings = [
        {
          containerPort = 8000
          protocol      = "tcp"
        }
      ]
      
      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "PORT"
          value = "8000"
        }
      ]
      
      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = var.database_url_secret_arn
        },
        {
          name      = "REDIS_URL" 
          valueFrom = var.redis_url_secret_arn
        },
        {
          name      = "JWT_SECRET_KEY"
          valueFrom = var.jwt_secret_arn
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.api_log_group.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      
      healthCheck = {
        command = ["CMD-SHELL", "curl -f http://localhost:8000/health || exit 1"]
        interval = 30
        timeout = 5
        retries = 3
        startPeriod = 60
      }
      
      essential = true
    }
  ])
  
  tags = {
    Environment = var.environment
    Project     = "roxcen-hms"
    Component   = "api-task"
  }
}

# ECS Service
resource "aws_ecs_service" "api_service" {
  name            = "roxcen-hms-api-${var.environment}"
  cluster         = aws_ecs_cluster.api_cluster.id
  task_definition = aws_ecs_task_definition.api_task.arn
  desired_count   = var.environment == "production" ? 2 : 1
  launch_type     = "FARGATE"
  platform_version = "LATEST"
  
  network_configuration {
    security_groups  = [aws_security_group.ecs_sg.id]
    subnets          = var.private_subnets
    assign_public_ip = false
  }
  
  load_balancer {
    target_group_arn = aws_lb_target_group.api_tg.arn
    container_name   = "roxcen-hms-api"
    container_port   = 8000
  }
  
  deployment_configuration {
    maximum_percent         = 200
    minimum_healthy_percent = 100
    
    deployment_circuit_breaker {
      enable   = true
      rollback = true
    }
  }
  
  depends_on = [aws_lb_listener.api_listener]
  
  tags = {
    Environment = var.environment
    Project     = "roxcen-hms"
    Component   = "api-service"
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "api_log_group" {
  name              = "/ecs/roxcen-hms-api-${var.environment}"
  retention_in_days = var.environment == "production" ? 30 : 7
  
  tags = {
    Environment = var.environment
    Project     = "roxcen-hms"
    Component   = "api-logs"
  }
}
