# Domain Validation Steps for HTTPS Setup

## Current Status
Your SSL certificate for `api-dev.roxcen.com` is in **PENDING_VALIDATION** status and needs domain validation to complete.

## Required Action: Update Domain Name Servers

### Step 1: Get the Name Servers from Terraform Output
From your terraform deployment, you got these name servers:
```
ns-1513.awsdns-61.org
ns-1832.awsdns-37.co.uk
ns-425.awsdns-53.com
ns-955.awsdns-55.net
```

### Step 2: Access Your Domain Registrar
Log in to where you registered `roxcen.com` (e.g., GoDaddy, Namecheap, Google Domains, etc.)

### Step 3: Update Name Servers

#### Option A: If you want to use subdomain delegation (Recommended)
1. Go to DNS Management for `roxcen.com`
2. Add NS (Name Server) records for the subdomain `api-dev`:
   ```
   Type: NS
   Name: api-dev
   Value: ns-1513.awsdns-61.org
   
   Type: NS  
   Name: api-dev
   Value: ns-1832.awsdns-37.co.uk
   
   Type: NS
   Name: api-dev  
   Value: ns-425.awsdns-53.com
   
   Type: NS
   Name: api-dev
   Value: ns-955.awsdns-55.net
   ```

#### Option B: If you want to use the existing roxcen.com hosted zone
1. Update terraform configuration to use existing hosted zone
2. Set `create_hosted_zone = false` in terraform.tfvars
3. Provide your existing `hosted_zone_id` for roxcen.com

### Step 4: Wait for DNS Propagation
- DNS changes can take 5-60 minutes to propagate globally
- You can check propagation status with: `nslookup api-dev.roxcen.com`

### Step 5: Verify DNS Resolution
Test if the subdomain resolves correctly:
```bash
# Check if subdomain resolves
nslookup api-dev.roxcen.com

# Check if it points to your load balancer
dig api-dev.roxcen.com
```

### Step 6: Re-run Terraform Apply
Once DNS propagates, the certificate validation will complete automatically:
```bash
cd /path/to/roxcen-infrastructure/environments/webapi/dev
terraform apply -auto-approve
```

## Alternative: Manual Certificate Validation

If you prefer to validate manually in AWS Console:

### Step 1: Go to AWS Certificate Manager
1. Open AWS Console → Certificate Manager
2. Find your certificate for `api-dev.roxcen.com`
3. Click on the certificate

### Step 2: Get Validation Records
You'll see DNS validation records like:
```
Name: _b091f76edf87c1ce492ade722973856b.api-dev.roxcen.com
Type: CNAME
Value: _xyz123.acm-validations.aws.
```

### Step 3: Add CNAME Records
Add these CNAME records to your `roxcen.com` DNS:
```
Type: CNAME
Name: _b091f76edf87c1ce492ade722973856b.api-dev
Value: _xyz123.acm-validations.aws.
```

## Expected Timeline
- **DNS Propagation**: 5-60 minutes
- **Certificate Validation**: 1-10 minutes after DNS propagates
- **Total Setup Time**: Usually 15-90 minutes

## Verification Commands
After setup, test your HTTPS endpoint:
```bash
# Test DNS resolution
nslookup api-dev.roxcen.com

# Test HTTPS endpoint (once certificate validates)
curl -I https://api-dev.roxcen.com/health

# Test certificate details
openssl s_client -connect api-dev.roxcen.com:443 -servername api-dev.roxcen.com
```

## Troubleshooting

### Certificate Still Pending After 1 Hour
1. Verify DNS records are correctly set
2. Check for typos in domain names
3. Ensure TTL is not too high (should be ≤ 300 seconds)
4. Clear your local DNS cache: `sudo dscacheutil -flushcache` (macOS)

### Domain Not Resolving
1. Wait longer for DNS propagation
2. Check with different DNS servers: `nslookup api-dev.roxcen.com 8.8.8.8`
3. Verify name servers are correctly set at registrar

## Next Steps After Validation
Once the certificate is validated and issued:

1. **Update Frontend Configuration**:
   ```javascript
   // Change from:
   const API_BASE_URL = "https://roxcen-hms-api-development-2011897162.ap-south-1.elb.amazonaws.com"
   
   // To:
   const API_BASE_URL = "https://api-dev.roxcen.com"
   ```

2. **Test API Endpoints**:
   ```bash
   curl https://api-dev.roxcen.com/api/v1/auth/token
   ```

3. **Deploy Updated Frontend** with new API URL

This will completely resolve the SSL security issues you're experiencing!
