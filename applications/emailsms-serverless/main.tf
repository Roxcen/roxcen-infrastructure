# EmailSMS Serverless Infrastructure with AWS Lambda
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
    key    = "applications/emailsms-serverless/terraform.tfstate"
    region = "ap-south-1"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "Roxcen"
      Service     = "EmailSMS-Serverless"
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
  name_prefix = "${var.project_name}-emailsms-serverless-${var.environment}"
  
  common_tags = {
    Project     = var.project_name
    Service     = "EmailSMS-Serverless"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
  
  # Shared VPC data (for RDS access)
  vpc_id             = data.terraform_remote_state.shared.outputs.vpc_id
  private_subnet_ids = data.terraform_remote_state.shared.outputs.private_subnet_ids
}

# Lambda function for API endpoints
resource "aws_lambda_function" "emailsms_api" {
  filename         = "emailsms_lambda.zip"
  function_name    = "${local.name_prefix}-api"
  role            = aws_iam_role.lambda_role.arn
  handler         = "main.lambda_handler"
  runtime         = "python3.11"
  timeout         = 30
  memory_size     = 512
  
  vpc_config {
    subnet_ids         = local.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }
  
  environment {
    variables = {
      ENVIRONMENT           = var.environment
      DATABASE_URL          = var.database_url
      REDIS_URL            = var.redis_url
      SENDGRID_API_KEY     = var.sendgrid_api_key
      TWILIO_ACCOUNT_SID   = var.twilio_account_sid
      TWILIO_AUTH_TOKEN    = var.twilio_auth_token
      TWILIO_PHONE_NUMBER  = var.twilio_phone_number
      SECRET_KEY           = var.jwt_secret_key
    }
  }
  
  tags = local.common_tags
}

# Lambda function for background queue processing
resource "aws_lambda_function" "emailsms_worker" {
  filename         = "emailsms_worker.zip"
  function_name    = "${local.name_prefix}-worker"
  role            = aws_iam_role.lambda_role.arn
  handler         = "worker.lambda_handler"
  runtime         = "python3.11"
  timeout         = 900  # 15 minutes max for background processing
  memory_size     = 1024
  
  vpc_config {
    subnet_ids         = local.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }
  
  environment {
    variables = {
      ENVIRONMENT           = var.environment
      DATABASE_URL          = var.database_url
      REDIS_URL            = var.redis_url
      SENDGRID_API_KEY     = var.sendgrid_api_key
      TWILIO_ACCOUNT_SID   = var.twilio_account_sid
      TWILIO_AUTH_TOKEN    = var.twilio_auth_token
      TWILIO_PHONE_NUMBER  = var.twilio_phone_number
      SECRET_KEY           = var.jwt_secret_key
    }
  }
  
  tags = local.common_tags
}

# API Gateway v2 (HTTP API - cheaper than REST API)
resource "aws_apigatewayv2_api" "emailsms" {
  name          = local.name_prefix
  protocol_type = "HTTP"
  description   = "EmailSMS Serverless API"
  
  cors_configuration {
    allow_credentials = false
    allow_headers     = ["*"]
    allow_methods     = ["*"]
    allow_origins     = ["*"]
    max_age          = 86400
  }
  
  tags = local.common_tags
}

# API Gateway Integration
resource "aws_apigatewayv2_integration" "emailsms" {
  api_id           = aws_apigatewayv2_api.emailsms.id
  integration_type = "AWS_PROXY"
  
  integration_method = "POST"
  integration_uri    = aws_lambda_function.emailsms_api.invoke_arn
}

# API Gateway Route (catch-all)
resource "aws_apigatewayv2_route" "emailsms" {
  api_id    = aws_apigatewayv2_api.emailsms.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.emailsms.id}"
}

# API Gateway Stage
resource "aws_apigatewayv2_stage" "emailsms" {
  api_id      = aws_apigatewayv2_api.emailsms.id
  name        = var.environment
  auto_deploy = true
  
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      path           = "$context.path"
      status         = "$context.status"
      responseLength = "$context.responseLength"
      userAgent      = "$context.identity.userAgent"
    })
  }
  
  tags = local.common_tags
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.emailsms_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.emailsms.execution_arn}/*/*"
}

# SQS Queue for email processing
resource "aws_sqs_queue" "email_queue" {
  name                      = "${local.name_prefix}-email-queue"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 1209600  # 14 days
  visibility_timeout_seconds = 900      # 15 minutes
  
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.email_dlq.arn
    maxReceiveCount     = 3
  })
  
  tags = local.common_tags
}

# Dead Letter Queue for failed emails
resource "aws_sqs_queue" "email_dlq" {
  name = "${local.name_prefix}-email-dlq"
  tags = local.common_tags
}

# SQS Queue for SMS processing
resource "aws_sqs_queue" "sms_queue" {
  name                      = "${local.name_prefix}-sms-queue"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 1209600
  visibility_timeout_seconds = 900
  
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.sms_dlq.arn
    maxReceiveCount     = 3
  })
  
  tags = local.common_tags
}

# Dead Letter Queue for failed SMS
resource "aws_sqs_queue" "sms_dlq" {
  name = "${local.name_prefix}-sms-dlq"
  tags = local.common_tags
}

# Lambda trigger for email queue
resource "aws_lambda_event_source_mapping" "email_queue" {
  event_source_arn = aws_sqs_queue.email_queue.arn
  function_name    = aws_lambda_function.emailsms_worker.arn
  batch_size       = 10
}

# Lambda trigger for SMS queue
resource "aws_lambda_event_source_mapping" "sms_queue" {
  event_source_arn = aws_sqs_queue.sms_queue.arn
  function_name    = aws_lambda_function.emailsms_worker.arn
  batch_size       = 10
}

# EventBridge for scheduled tasks (optional)
resource "aws_cloudwatch_event_rule" "cleanup_schedule" {
  name                = "${local.name_prefix}-cleanup"
  description         = "Cleanup old messages and logs"
  schedule_expression = "rate(1 day)"
  
  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "cleanup_lambda" {
  rule      = aws_cloudwatch_event_rule.cleanup_schedule.name
  target_id = "CleanupTarget"
  arn       = aws_lambda_function.emailsms_worker.arn
  
  input = jsonencode({
    task = "cleanup"
  })
}

# Lambda permission for EventBridge
resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.emailsms_worker.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cleanup_schedule.arn
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/apigateway/${local.name_prefix}"
  retention_in_days = var.environment == "production" ? 30 : 7
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "lambda_api_logs" {
  name              = "/aws/lambda/${aws_lambda_function.emailsms_api.function_name}"
  retention_in_days = var.environment == "production" ? 30 : 7
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "lambda_worker_logs" {
  name              = "/aws/lambda/${aws_lambda_function.emailsms_worker.function_name}"
  retention_in_days = var.environment == "production" ? 30 : 7
  tags              = local.common_tags
}

# Security Group for Lambda (VPC access)
resource "aws_security_group" "lambda" {
  name_prefix = "${local.name_prefix}-lambda"
  vpc_id      = local.vpc_id
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-lambda"
  })
}

# Security Group Rule to allow Lambda access to RDS
resource "aws_security_group_rule" "lambda_to_rds" {
  count                    = var.environment == "development" ? 1 : 0
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lambda.id
  security_group_id        = data.terraform_remote_state.shared.outputs.dev_rds_security_group_id
  description              = "Allow Lambda access to Development PostgreSQL RDS"
}

resource "aws_security_group_rule" "lambda_to_rds_prod" {
  count                    = var.environment == "production" ? 1 : 0
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lambda.id
  security_group_id        = data.terraform_remote_state.shared.outputs.prod_rds_security_group_id
  description              = "Allow Lambda access to Production PostgreSQL RDS"
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${local.name_prefix}-lambda-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  
  tags = local.common_tags
}

# IAM Policy for Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${local.name_prefix}-lambda-policy"
  role = aws_iam_role.lambda_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:SendMessage"
        ]
        Resource = [
          aws_sqs_queue.email_queue.arn,
          aws_sqs_queue.sms_queue.arn,
          aws_sqs_queue.email_dlq.arn,
          aws_sqs_queue.sms_dlq.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      }
    ]
  })
}
