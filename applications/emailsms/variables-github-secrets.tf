# Updated variables for GitHub Secrets approach (cost-free)
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "roxcen"
}

variable "environment" {
  description = "Environment name"
  type        = string
  # validation {
  #   condition     = contains(["development", "production"], var.environment)
  #   error_message = "Environment must be either 'development' or 'production'."
  # }
}

variable "database_url" {
  description = "Database connection URL"
  type        = string
  sensitive   = true
}

variable "redis_url" {
  description = "Redis connection URL"
  type        = string
  sensitive   = true
  default     = ""
}

# Direct secret variables (from GitHub Secrets via CI/CD)
variable "sendgrid_api_key" {
  description = "SendGrid API Key"
  type        = string
  sensitive   = true
}

variable "twilio_account_sid" {
  description = "Twilio Account SID"
  type        = string
  sensitive   = true
}

variable "twilio_auth_token" {
  description = "Twilio Auth Token"
  type        = string
  sensitive   = true
}

variable "twilio_phone_number" {
  description = "Twilio Phone Number"
  type        = string
  sensitive   = true
  default     = ""
}

variable "jwt_secret_key" {
  description = "JWT Secret Key"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Custom domain name for the API (optional)"
  type        = string
  default     = ""
}

variable "ssl_certificate_arn" {
  description = "ARN of the SSL certificate for custom domain"
  type        = string
  default     = ""
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 512
}

variable "worker_timeout" {
  description = "Worker lambda timeout in seconds"
  type        = number
  default     = 900
}

variable "worker_memory_size" {
  description = "Worker lambda memory size in MB"
  type        = number
  default     = 1024
}

variable "enable_vpc" {
  description = "Enable VPC configuration for Lambda (required for RDS access)"
  type        = bool
  default     = true
}
