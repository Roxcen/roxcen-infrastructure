# Roxcen Domain Configuration

## Domain Structure

**Main Domain:** `roxcen.com`

### Subdomains for API Endpoints

| Environment | Subdomain | Full URL | Purpose |
|-------------|-----------|----------|---------|
| Development | `api-dev` | `https://api-dev.roxcen.com` | Development API endpoint |
| Production | `api` | `https://api.roxcen.com` | Production API endpoint |

### Current Issue Resolution

**Before (causing SSL/security issues):**
```
https://roxcen-hms-api-development-2011897162.ap-south-1.elb.amazonaws.com/api/v1/auth/token
```

**After (secure HTTPS with custom domain):**
```
https://api-dev.roxcen.com/api/v1/auth/token
```

## Frontend Configuration Updates

### Development Environment
Update your `hosp_business_app` configuration:

```javascript
// config/development.js or .env.development
const API_BASE_URL = "https://api-dev.roxcen.com"
```

### Production Environment
```javascript
// config/production.js or .env.production
const API_BASE_URL = "https://api.roxcen.com"
```

## DNS Configuration Steps

1. **For Development (api-dev.roxcen.com):**
   - Terraform will create a new hosted zone
   - You'll need to add NS records to your main roxcen.com domain

2. **For Production (api.roxcen.com):**
   - Use existing roxcen.com hosted zone
   - Terraform will add A record pointing to ALB

## Deployment Commands

### Development
```bash
cd roxcen-infrastructure/environments/webapi/dev
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your specific values
terraform init
terraform plan
terraform apply
```

### Production
```bash
cd roxcen-infrastructure/environments/webapi/prod
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your specific values
terraform init
terraform plan
terraform apply
```

## Security Benefits

✅ **Eliminates mixed content warnings**
✅ **Encrypts all API traffic**
✅ **Professional domain structure**
✅ **Browser security compliance**
✅ **Proper CORS handling**
✅ **SEO and trust benefits**
