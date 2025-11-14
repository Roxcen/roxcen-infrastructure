# 🚀 **Roxcen Infrastructure Deployment Guide**

## **📋 Overview**

This guide covers the complete deployment of Roxcen HMS API infrastructure using Terraform modules and AWS services.

## **🏗️ Architecture Components**

### **1. Shared Infrastructure**
- **VPC**: Private networking with public/private subnets across 2 AZs
- **RDS PostgreSQL**: Managed database with Multi-AZ, Performance Insights, Enhanced Monitoring
- **Security Groups**: Database and application-specific security configurations
- **Secrets Manager**: Database credentials and connection strings
- **CloudWatch**: Logging and monitoring infrastructure

### **2. Environment-Specific Resources**
- **ECS Fargate**: Containerized application hosting
- **Application Load Balancer**: HTTPS termination and routing
- **Auto Scaling**: Dynamic scaling based on CPU/memory utilization
- **CloudWatch Alarms**: Environment-specific monitoring and alerts
- **ECR**: Container image registry

## **📁 Directory Structure**

```
roxcen-infrastructure/
├── modules/
│   ├── vpc/          # VPC networking module
│   ├── rds/          # PostgreSQL database module
│   └── ecs-api/      # ECS application module
├── environments/
│   └── webapi/
│       ├── dev/      # Development environment
│       └── prod/     # Production environment
├── scripts/
│   └── deploy.sh     # Deployment automation script
└── terraform.tfvars  # Shared infrastructure configuration
```

## **🔧 Prerequisites**

### **1. AWS CLI & Terraform Setup**
```bash
# Verify AWS CLI
aws --version
aws sts get-caller-identity

# Verify Terraform
terraform --version  # Should be >= 1.0
```

### **2. Required AWS Permissions**
Your AWS user/role needs:
- `AdministratorAccess` (for initial setup)
- Or specific permissions for VPC, ECS, RDS, ECR, Secrets Manager, CloudWatch

### **3. GitHub Secrets Configuration**
Set these secrets in both repositories:

**roxcen-infrastructure repository:**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION` = `ap-south-1`

**webapi repository:**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION` = `ap-south-1`

## **🚀 Deployment Steps**

### **Step 1: Initialize S3 Backend**

Create the Terraform state bucket (one-time setup):

```bash
cd roxcen-infrastructure

# Create S3 bucket for Terraform state
aws s3 mb s3://roxcen-terraform-state --region ap-south-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket roxcen-terraform-state \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket roxcen-terraform-state \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }
    ]
  }'
```

### **Step 2: Deploy Shared Infrastructure**

Deploy VPC, networking, and database:

```bash
# Initialize and deploy shared infrastructure
./scripts/deploy.sh shared init
./scripts/deploy.sh shared plan
./scripts/deploy.sh shared apply

# Verify deployment
terraform output
```

**Expected Outputs:**
- VPC ID and subnet IDs
- RDS endpoint and database secret ARN
- Security group IDs

### **Step 3: Configure SSL Certificate**

Create SSL certificate in AWS Certificate Manager:

```bash
# Request certificate (replace with your domain)
aws acm request-certificate \
  --domain-name "dev-api.roxcen.com" \
  --validation-method DNS \
  --region ap-south-1

# Note the certificate ARN for terraform.tfvars
```

### **Step 4: Update Environment Configuration**

Update `environments/webapi/dev/terraform.tfvars`:

```hcl
# Update with actual certificate ARN
ssl_certificate_arn = "arn:aws:acm:ap-south-1:YOUR_ACCOUNT:certificate/YOUR_CERT_ID"

# Create additional secrets manually or via Terraform
redis_url_secret_arn = "arn:aws:secretsmanager:ap-south-1:YOUR_ACCOUNT:secret:dev-redis-url"
jwt_secret_arn       = "arn:aws:secretsmanager:ap-south-1:YOUR_ACCOUNT:secret:jwt-secret-key"
```

### **Step 5: Deploy Development Environment**

```bash
# Deploy development API environment
./scripts/deploy.sh webapi-dev init
./scripts/deploy.sh webapi-dev plan
./scripts/deploy.sh webapi-dev apply

# Verify deployment
cd environments/webapi/dev
terraform output
```

### **Step 6: Deploy Application Code**

The WebAPI repository GitHub Actions will automatically:
1. Build Docker image
2. Push to ECR
3. Update ECS service
4. Perform health checks

Trigger deployment by pushing to `main` branch in webapi repository.

### **Step 7: Configure DNS (Optional)**

Point your domain to the load balancer:

```bash
# Get load balancer DNS name
cd environments/webapi/dev
terraform output alb_dns_name

# Create Route 53 CNAME record:
# dev-api.roxcen.com -> your-alb-dns-name.ap-south-1.elb.amazonaws.com
```

## **🔍 Verification & Testing**

### **1. Infrastructure Health Check**

```bash
# Check ECS service status
aws ecs describe-services \
  --cluster roxcen-development-cluster \
  --services roxcen-development-service \
  --region ap-south-1

# Check RDS status
aws rds describe-db-instances \
  --db-instance-identifier roxcen-development-db \
  --region ap-south-1
```

### **2. Application Health Check**

```bash
# Test health endpoint
curl https://dev-api.roxcen.com/health

# Expected response:
# {"status": "healthy", "timestamp": "2024-01-XX"}
```

### **3. Database Connectivity**

```bash
# Get database credentials from Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id "roxcen-development-db-credentials" \
  --region ap-south-1

# Test connection (from within VPC or via bastion host)
psql -h your-rds-endpoint -U roxcen_admin -d roxcen_hms
```

## **📊 Monitoring & Logging**

### **CloudWatch Dashboards**
- ECS service metrics (CPU, memory, task count)
- RDS performance metrics (connections, CPU, I/O)
- Application Load Balancer metrics (requests, response times)

### **CloudWatch Alarms**
- High CPU utilization (> 80%)
- Database connection count (> 80% max)
- Application errors (4xx/5xx responses)

### **Log Groups**
- `/aws/ecs/roxcen-development` - Application logs
- `/aws/rds/instance/roxcen-development-db/postgresql` - Database logs

## **🔒 Security Features**

### **Network Security**
- Private subnets for database and application
- Security groups with minimal required access
- VPC endpoints for AWS services (optional)

### **Data Security**
- RDS encryption at rest and in transit
- Secrets Manager for credential management
- IAM roles with least privilege principles

### **Application Security**
- HTTPS-only load balancer
- Container security scanning via ECR
- Regular security updates via automated deployments

## **🛠️ Maintenance & Updates**

### **Terraform State Management**
- State stored in S3 with versioning
- State locking via DynamoDB (optional)
- Regular state backups

### **Database Maintenance**
- Automated backups (7-day retention for dev)
- Maintenance windows during low usage
- Performance Insights monitoring

### **Application Updates**
- Zero-downtime deployments via ECS rolling updates
- Automated rollback on health check failures
- Container image vulnerability scanning

## **🚨 Troubleshooting**

### **Common Issues**

**1. ECS Tasks Not Starting**
```bash
# Check task definition and logs
aws ecs describe-tasks --cluster CLUSTER_NAME --tasks TASK_ARN
aws logs get-log-events --log-group-name /aws/ecs/roxcen-development
```

**2. Database Connection Issues**
```bash
# Verify security groups and network ACLs
# Check database status and parameter groups
# Validate Secrets Manager permissions
```

**3. Load Balancer Health Checks Failing**
```bash
# Verify target group health
# Check application /health endpoint
# Review security group rules for ALB -> ECS communication
```

### **Rollback Procedures**

**Infrastructure Rollback:**
```bash
# Rollback to previous Terraform state
terraform apply -var="ecs_desired_count=0"  # Scale down
terraform apply -target="module.ecs_api" -auto-approve  # Restore previous
```

**Application Rollback:**
```bash
# Via ECS console or CLI
aws ecs update-service \
  --cluster roxcen-development-cluster \
  --service roxcen-development-service \
  --task-definition previous-task-definition-arn
```

## **📈 Scaling Considerations**

### **Development Environment**
- 1 ECS task, 512 CPU, 1GB memory
- Single AZ RDS (cost optimization)
- Basic monitoring and alerting

### **Production Environment**
- Multi-AZ RDS with read replicas
- Auto Scaling Group with 2-10 tasks
- Enhanced monitoring and alerting
- WAF and CloudFront integration

## **💰 Cost Optimization**

### **Development**
- Use t3.micro for RDS
- Single AZ deployment
- Scheduled task shutdown (optional)

### **Production**
- Reserved instances for predictable workloads
- S3 Intelligent Tiering for logs
- CloudWatch log retention policies

---

## **🆘 Support & Contact**

For deployment issues or questions:
- Review CloudWatch logs and metrics
- Check GitHub Actions workflow status
- Validate AWS permissions and quotas
- Review this guide and Terraform documentation

**Happy Deploying! 🚀**
