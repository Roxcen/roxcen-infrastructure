variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the API"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnets" {
  description = "Public subnet IDs"
  type        = list(string)
}

variable "private_subnets" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "ecs_task_cpu" {
  description = "ECS task CPU"
  type        = number
}

variable "ecs_task_memory" {
  description = "ECS task memory"
  type        = number
}

variable "ecs_desired_count" {
  description = "ECS desired count"
  type        = number
}

variable "ssl_certificate_arn" {
  description = "SSL certificate ARN"
  type        = string
}

variable "database_url_secret_arn" {
  description = "Database URL secret ARN"
  type        = string
}

variable "redis_url_secret_arn" {
  description = "Redis URL secret ARN"
  type        = string
}

variable "jwt_secret_arn" {
  description = "JWT secret ARN"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
