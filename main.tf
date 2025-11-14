# Terraform configuration for shared infrastructure
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
    key    = "shared/terraform.tfstate"
    region = "ap-south-1"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "Roxcen"
      ManagedBy   = "Terraform"
      Environment = "shared"
    }
  }
}

# Shared VPC Module
module "vpc" {
  source = "./modules/vpc"
  
  project_name = var.project_name
  environment  = "shared"
  
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# RDS module will be added later when needed
# Shared RDS Module for Development Environment
module "rds_dev" {
  source = "./modules/rds"
  
  project_name = var.project_name
  environment  = "development"
  
  vpc_id              = module.vpc.vpc_id
  vpc_cidr           = var.vpc_cidr
  private_subnet_ids = module.vpc.private_subnet_ids
  allowed_security_groups = [module.vpc.default_security_group_id]
  
  # Development configuration (Maximum cost optimization)
  instance_class         = "db.t3.micro"  # Free tier eligible
  allocated_storage     = 20              # Minimum for gp3
  max_allocated_storage = 20              # No auto-scaling to control costs
  backup_retention_period = 0             # No backups for dev (saves storage)
  backup_window         = "03:00-04:00"   # Required even with 0 retention
  multi_az             = false            # Single AZ for cost savings
  deletion_protection  = false            # Allow easy deletion
  skip_final_snapshot  = true             # No final snapshot
  enhanced_monitoring  = false            # Disable paid monitoring
  performance_insights_enabled = false    # Disable paid insights
  
  database_name    = var.db_name
  master_username  = var.db_username
  
  count = var.create_dev_rds ? 1 : 0
}

# Shared RDS Module for Production Environment
module "rds_prod" {
  source = "./modules/rds"
  
  project_name = var.project_name
  environment  = "production"
  
  vpc_id              = module.vpc.vpc_id
  vpc_cidr           = var.vpc_cidr
  private_subnet_ids = module.vpc.private_subnet_ids
  allowed_security_groups = [module.vpc.default_security_group_id]
  
  # Production configuration
  instance_class         = "db.r6g.large"  # Production-grade instance
  allocated_storage     = 100
  max_allocated_storage = 1000
  multi_az             = true
  deletion_protection  = true
  skip_final_snapshot  = false
  enhanced_monitoring  = true
  performance_insights_enabled = true
  
  database_name    = var.db_name
  master_username  = var.db_username
  
  count = var.create_prod_rds ? 1 : 0
}

# Monitoring and Security modules will be added later
# module "monitoring" {
#   source = "./shared/monitoring"  
# }

# module "security" {
#   source = "./shared/security"
# }
