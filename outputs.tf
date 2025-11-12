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

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = var.create_shared_rds ? module.rds[0].endpoint : null
}

output "rds_port" {
  description = "RDS instance port"
  value       = var.create_shared_rds ? module.rds[0].port : null
}
