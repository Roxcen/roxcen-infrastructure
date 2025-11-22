# EmailSMS Serverless Infrastructure with GitHub Secrets (Cost-Free)
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

locals {
  name_prefix = "${var.project_name}-emailsms-${var.environment}"
  
  common_tags = {
    Project     = var.project_name
    Service     = "EmailSMS-Serverless" 
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Lambda deployment bucket
resource "aws_s3_bucket" "lambda_deployments" {
  bucket = "${local.name_prefix}-lambda-deployments"
  tags   = local.common_tags
}

# Placeholder Lambda zip
data "archive_file" "lambda_placeholder" {
  type        = "zip"
  output_path = "${path.module}/lambda_placeholder.zip"
  
  source {
    content  = "def lambda_handler(event, context): return {'statusCode': 200, 'body': 'Placeholder'}"
    filename = "main.py"
  }
}

# Lambda function for API endpoints
resource "aws_lambda_function" "emailsms_api" {
  function_name    = "${local.name_prefix}-api"
  role            = aws_iam_role.lambda_role.arn
  handler         = "main.lambda_handler"
  runtime         = "python3.11"
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size
  
  # Use placeholder initially, CI/CD will update
  filename         = data.archive_file.lambda_placeholder.output_path
  source_code_hash = data.archive_file.lambda_placeholder.output_base64sha256
  
  environment {
    variables = {
      ENVIRONMENT         = var.environment
      DATABASE_URL        = var.database_url
      REDIS_URL          = var.redis_url
      SQS_EMAIL_QUEUE_URL = aws_sqs_queue.email_queue.url
      SQS_SMS_QUEUE_URL   = aws_sqs_queue.sms_queue.url
      # Direct secret values from GitHub Secrets (passed via CI/CD)
      SENDGRID_API_KEY    = var.sendgrid_api_key
      TWILIO_ACCOUNT_SID  = var.twilio_account_sid
      TWILIO_AUTH_TOKEN   = var.twilio_auth_token
      TWILIO_PHONE_NUMBER = var.twilio_phone_number
      JWT_SECRET_KEY      = var.jwt_secret_key
    }
  }
  
  tags = local.common_tags
}

# Lambda function for background queue processing  
resource "aws_lambda_function" "emailsms_worker" {
  function_name    = "${local.name_prefix}-worker"
  role            = aws_iam_role.lambda_role.arn
  handler         = "worker.lambda_handler"
  runtime         = "python3.11"
  timeout         = var.worker_timeout
  memory_size     = var.worker_memory_size
  
  # Use placeholder initially, CI/CD will update
  filename         = data.archive_file.lambda_placeholder.output_path
  source_code_hash = data.archive_file.lambda_placeholder.output_base64sha256
  
  environment {
    variables = {
      ENVIRONMENT         = var.environment
      DATABASE_URL        = var.database_url
      REDIS_URL          = var.redis_url
      SQS_EMAIL_QUEUE_URL = aws_sqs_queue.email_queue.url
      SQS_SMS_QUEUE_URL   = aws_sqs_queue.sms_queue.url
      # Direct secret values from GitHub Secrets (passed via CI/CD)
      SENDGRID_API_KEY    = var.sendgrid_api_key
      TWILIO_ACCOUNT_SID  = var.twilio_account_sid
      TWILIO_AUTH_TOKEN   = var.twilio_auth_token
      TWILIO_PHONE_NUMBER = var.twilio_phone_number
      JWT_SECRET_KEY      = var.jwt_secret_key
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

# API Gateway Route (root)
resource "aws_apigatewayv2_route" "emailsms_root" {
  api_id    = aws_apigatewayv2_api.emailsms.id
  route_key = "ANY /"
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
  visibility_timeout_seconds = var.worker_timeout + 60
  
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
  visibility_timeout_seconds = var.worker_timeout + 60
  
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

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/apigateway/${local.name_prefix}"
  retention_in_days = var.environment == "production" ? 30 : 7
  tags              = local.common_tags
}

# Lambda CloudWatch log groups are automatically created by AWS Lambda
# No need to manage them explicitly in Terraform
  
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

# Basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# IAM Policy for Lambda - GitHub Secrets Version
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
