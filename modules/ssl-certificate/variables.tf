variable "domain_name" {
  description = "Domain name for SSL certificate"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "create_hosted_zone" {
  description = "Whether to create a new hosted zone"
  type        = bool
  default     = true
}

variable "existing_hosted_zone_id" {
  description = "Existing hosted zone ID (if not creating new one)"
  type        = string
  default     = ""
}
