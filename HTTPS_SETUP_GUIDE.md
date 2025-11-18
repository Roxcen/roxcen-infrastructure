# HTTPS Setup Guide for WebAPI

## Overview
This guide will help yo# After (HTTPS - secure)
const API_BASE_URL = "https://api-dev.roxcen.com"set up HTTPS for your webapi to resolve the SSL security issues when your frontend makes requests to the API.

## Prerequisites
1. A domain name registered with a domain registrar (e.g., GoDaddy, Route53, Namecheap)
2. AWS CLI configured with appropriate permissions
3. Terraform installed

## Steps to Enable HTTPS

### 1. Configure Domain Settings

Update the `terraform.tfvars` file in `/environments/webapi/dev/`:

```hcl
# Domain Configuration
domain_name = "api-dev.roxcen.com"  # Development API subdomain
create_hosted_zone = true  # Set to false if you already have a hosted zone for this domain

# Other required variables
environment = "development"
project_name = "roxcen-hms"
jwt_secret_arn = "arn:aws:secretsmanager:ap-south-1:269010807913:secret:roxcen/development/jwt-secret-XXXXXX"
ecs_task_cpu = 512
ecs_task_memory = 1024
ecs_desired_count = 1
```

### 2. Deploy Infrastructure

```bash
cd /path/to/roxcen-infrastructure/environments/webapi/dev
terraform init
terraform plan
terraform apply
```

### 3. Update Domain Registrar

After terraform apply, you'll get name servers in the output:
```
name_servers = [
  "ns-xxx.awsdns-xx.com",
  "ns-xxx.awsdns-xx.co.uk",
  "ns-xxx.awsdns-xx.net",
  "ns-xxx.awsdns-xx.org"
]
```

**Important:** Update your domain registrar's DNS settings to use these name servers.

### 4. Wait for DNS Propagation

DNS propagation can take 5-60 minutes. You can check status with:
```bash
nslookup api-dev.roxcen.com
```

### 5. Update Frontend Configuration

Update your frontend (`hosp_business_app`) to use the new HTTPS URL:
```javascript
// Before (HTTP - causing security issues)
const API_BASE_URL = "https://roxcen-hms-api-development-2011897162.ap-south-1.elb.amazonaws.com"

// After (HTTPS - secure)
const API_BASE_URL = "To:
```
https://api-dev.roxcen.com
```"
```

### 6. Test the Setup

Test your API endpoints:
```bash
curl https://api-dev.roxcen.com/health
curl https://api-dev.roxcen.com/api/v1/auth/token
```

## Troubleshooting

### Certificate Validation Issues
- Ensure domain name servers are updated at your registrar
- Wait for DNS propagation (up to 60 minutes)
- Check certificate status in AWS Console > Certificate Manager

### Domain Not Resolving
- Verify name servers are correctly set at your domain registrar
- Use `dig` or `nslookup` to check DNS resolution
- Wait for DNS propagation

### HTTPS Not Working
- Ensure certificate is validated and issued
- Check ALB listener configuration
- Verify security groups allow port 443

## Cost Implications
- Route53 hosted zone: ~$0.50/month
- SSL certificate: Free (AWS Certificate Manager)
- No additional ALB costs (already configured)

## Security Benefits
- ✅ Eliminates mixed content warnings
- ✅ Encrypts data in transit
- ✅ Improves browser security compliance
- ✅ Enables proper CORS handling
- ✅ Required for production deployment
