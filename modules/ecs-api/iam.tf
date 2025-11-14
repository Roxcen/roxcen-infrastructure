# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "roxcen-hms-api-${var.environment}-execution-role"
  
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
  
  tags = {
    Environment = var.environment
    Project     = "roxcen-hms"
    Component   = "ecs-execution-role"
  }
}

# ECS Task Role
resource "aws_iam_role" "ecs_task_role" {
  name = "roxcen-hms-api-${var.environment}-task-role"
  
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
  
  tags = {
    Environment = var.environment
    Project     = "roxcen-hms"
    Component   = "ecs-task-role"
  }
}

# Attach ECS Task Execution Role Policy
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Custom policy for accessing secrets
resource "aws_iam_role_policy" "ecs_secrets_policy" {
  name = "roxcen-hms-api-${var.environment}-secrets-policy"
  role = aws_iam_role.ecs_task_execution_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          var.database_url_secret_arn,
          var.jwt_secret_arn
        ]
      }
    ]
  })
}

# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name_prefix = "roxcen-hms-api-alb-${var.environment}-"
  vpc_id      = var.vpc_id
  
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
  
  tags = {
    Name        = "roxcen-hms-api-alb-${var.environment}-sg"
    Environment = var.environment
    Project     = "roxcen-hms"
    Component   = "alb-security-group"
  }
}

# ECS Security Group
resource "aws_security_group" "ecs_sg" {
  name_prefix = "roxcen-hms-api-ecs-${var.environment}-"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description     = "API traffic from ALB"
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }
  
  tags = {
    Name        = "roxcen-hms-api-ecs-${var.environment}-sg"
    Environment = var.environment
    Project     = "roxcen-hms"
    Component   = "ecs-security-group"
  }
}
