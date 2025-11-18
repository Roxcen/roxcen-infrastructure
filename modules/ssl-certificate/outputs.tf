output "certificate_arn" {
  description = "ARN of the SSL certificate"
  value       = aws_acm_certificate_validation.api_cert_validation.certificate_arn
}

output "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  value       = var.create_hosted_zone ? aws_route53_zone.main[0].zone_id : var.existing_hosted_zone_id
}

output "name_servers" {
  description = "Route53 name servers (if creating hosted zone)"
  value       = var.create_hosted_zone ? aws_route53_zone.main[0].name_servers : []
}
