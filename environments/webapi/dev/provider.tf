terraform {
  required_version = ">= 1.5"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    # Configure these values when running terraform init
    # bucket = "roxcen-terraform-state"
    # key    = "api/dev/terraform.tfstate"
    # region = "ap-south-1"
    # encrypt = true
    # dynamodb_table = "terraform-state-locks"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "roxcen-hms"
      Component   = "api"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
