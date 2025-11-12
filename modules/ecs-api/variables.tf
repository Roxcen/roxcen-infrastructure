variable "environment" {
  description = "Environment name (development, production)"
  type        = string
  validation {
    condition     = contains(["development", "production"], var.environment)
    error_message = "Environment must be either 'development' or 'production'."
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "ssl_certificate_arn" {
  description = "SSL certificate ARN for HTTPS"
  type        = string
}

variable "database_url_secret_arn" {
  description = "ARN of the secret containing database URL"
  type        = string
}

variable "redis_url_secret_arn" {
  description = "ARN of the secret containing Redis URL"
  type        = string
}

variable "jwt_secret_arn" {
  description = "ARN of the secret containing JWT secret key"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the API"
  type        = string
  default     = ""
}
