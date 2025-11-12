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

# Shared RDS Module (if needed)
module "rds" {
  source = "./modules/rds"
  
  project_name = var.project_name
  environment  = "shared"
  
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  allowed_security_groups = [module.vpc.default_security_group_id]
  
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
  
  count = var.create_shared_rds ? 1 : 0
}

# Shared Monitoring
module "monitoring" {
  source = "./shared/monitoring"
  
  project_name = var.project_name
  
  sns_topic_arn = var.sns_topic_arn
}

# Shared Security
module "security" {
  source = "./shared/security"
  
  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
}
