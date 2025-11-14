aws_region = "ap-south-1"
project_name = "roxcen"
vpc_cidr = "10.0.0.0/16"
availability_zones = ["ap-south-1a", "ap-south-1b"]
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]

# RDS Database Configuration
create_dev_rds = true   # Create development database
create_prod_rds = false # Create production database when ready

# Database settings
db_name = "roxcen_hms"
db_username = "roxcen_admin"

# SNS topic for alerts (create manually or via separate terraform)
# sns_topic_arn = "arn:aws:sns:ap-south-1:123456789012:roxcen-alerts"
