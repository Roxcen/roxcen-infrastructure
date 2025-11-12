aws_region = "ap-south-1"
project_name = "roxcen"
vpc_cidr = "10.0.0.0/16"
availability_zones = ["ap-south-1a", "ap-south-1b"]
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]

# Shared RDS (optional - set to true if needed)
create_shared_rds = false

# Database configuration (only used if create_shared_rds = true)
# db_password = "your-secure-password"

# SNS topic for alerts (create manually or via separate terraform)
# sns_topic_arn = "arn:aws:sns:ap-south-1:123456789012:roxcen-alerts"
