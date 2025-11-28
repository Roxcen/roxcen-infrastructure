output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "default_security_group_id" {
  description = "ID of the default security group"
  value       = module.vpc.default_security_group_id
}

# RDS outputs will be added when RDS module is implemented
output "dev_rds_endpoint" {
  description = "Development RDS instance endpoint"
  value       = var.create_dev_rds ? module.rds_dev[0].db_endpoint : null
}

output "dev_rds_security_group_id" {
  description = "Development RDS security group ID"
  value       = var.create_dev_rds ? module.rds_dev[0].db_security_group_id : null
}

output "dev_rds_credentials_secret_arn" {
  description = "Development RDS credentials secret ARN"
  value       = var.create_dev_rds ? module.rds_dev[0].db_credentials_secret_arn : null
}

output "prod_rds_endpoint" {
  description = "Production RDS instance endpoint"
  value       = var.create_prod_rds ? module.rds_prod[0].db_endpoint : null
}

output "prod_rds_security_group_id" {
  description = "Production RDS security group ID"
  value       = var.create_prod_rds ? module.rds_prod[0].db_security_group_id : null
}

output "prod_rds_credentials_secret_arn" {
  description = "Production RDS credentials secret ARN"
  value       = var.create_prod_rds ? module.rds_prod[0].db_credentials_secret_arn : null
}
