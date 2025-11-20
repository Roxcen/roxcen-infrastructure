# EmailSMS Serverless Infrastructure

AWS Lambda-based serverless infrastructure for the EmailSMS microservice with cost-optimized, auto-scaling deployment.

## 🏗️ Architecture Overview

```
API Gateway → Lambda (API) → SQS Queues → Lambda (Worker) → External APIs
    ↓              ↓                            ↓
CloudWatch    S3 (Code)                   RDS/Secrets
```

### Key Components

1. **API Gateway HTTP API** - Cost-effective API endpoint
2. **Lambda Functions** - Serverless compute (API + Worker)
3. **SQS Queues** - Reliable message queuing for emails/SMS
4. **S3 Bucket** - Lambda deployment packages
5. **CloudWatch** - Comprehensive logging and monitoring
6. **Secrets Manager** - Secure API key storage

## 💰 Cost Benefits

| Aspect | ECS Fargate | Lambda Serverless | Savings |
|--------|-------------|-------------------|---------|
| **Development** | $15-20/month | $1-5/month | **75-85%** |
| **Production** | $50-80/month | $10-30/month | **60-80%** |
| **Scaling** | Manual/Auto | Automatic | **100%** |
| **Management** | Medium | Minimal | **High** |

## 🚀 Deployment Guide

### Prerequisites

1. **Shared Infrastructure**: Deploy VPC and shared resources
2. **AWS Credentials**: Configure AWS CLI access
3. **Terraform**: Install Terraform >= 1.0
4. **Secrets**: Create required secrets in AWS Secrets Manager

### Quick Start

```bash
# 1. Deploy infrastructure
cd roxcen-infrastructure/applications/emailsms
./deploy.sh development plan
./deploy.sh development apply

# 2. Deploy application code via CI/CD
# Push to release branch or trigger manually in GitHub Actions

# 3. Test deployment
curl $(terraform output -raw api_gateway_url)/health
```

### Environment Configuration

#### Development
- **Lambda**: 512MB memory, 30s timeout
- **Worker**: 512MB memory, 5min timeout
- **Domain**: API Gateway URL
- **SSL**: Not required

#### Production
- **Lambda**: 1GB memory, 30s timeout
- **Worker**: 2GB memory, 15min timeout
- **Domain**: Custom domain with SSL
- **SSL**: ACM certificate required

## 📦 CI/CD Pipeline

The pipeline follows the same pattern as `hosp_business_app` with serverless optimizations:

### Triggers
- **Auto**: Release branch push (`release/YYMMDD`)
- **Manual**: Workflow dispatch

### Stages
1. **🎯 Setup** - Extract release info
2. **🏗️ Build** - Create Lambda packages
3. **🚀 Dev Deploy** - Auto-deploy to development
4. **🏭 Prod Deploy** - Manual approval required
5. **🔄 Merge PR** - Auto-merge to main

### Lambda Packages

#### API Package
- FastAPI app with Mangum adapter
- All routers, services, models included
- Optimized dependencies only

#### Worker Package
- SQS message processors
- Email/SMS sending logic
- Scheduled cleanup tasks

## 🔐 Security Implementation

### IAM Permissions
- **Least privilege** access
- **Resource-specific** permissions
- **Environment isolation**

### Network Security
- **VPC integration** for RDS access
- **Security groups** for traffic control
- **Private subnets** for data processing

### Data Protection
- **Secrets Manager** for API keys
- **Encryption at rest** (S3, SQS)
- **TLS in transit** (API Gateway, RDS)

## 📊 Monitoring & Observability

### CloudWatch Logs
```bash
# API Gateway logs
/aws/apigateway/roxcen-emailsms-{env}

# Lambda function logs  
/aws/lambda/roxcen-emailsms-{env}-api
/aws/lambda/roxcen-emailsms-{env}-worker
```

### Key Metrics
- **API Gateway**: Request count, latency, errors
- **Lambda**: Invocations, duration, errors
- **SQS**: Messages sent, received, failed

### Alarms & Alerts
- High error rates (>5%)
- Long processing times (>30s)
- Queue backlog (>1000 messages)

## 🔧 Configuration Files

### Infrastructure
- `main.tf` - Core infrastructure resources
- `variables.tf` - Configurable parameters
- `outputs.tf` - Deployment information
- `deploy.sh` - Deployment automation

### Environment Variables
```bash
# Application settings
ENVIRONMENT=development
DATABASE_URL=postgresql://...
SQS_EMAIL_QUEUE_URL=https://sqs...
SQS_SMS_QUEUE_URL=https://sqs...

# Secrets (from AWS Secrets Manager)
SENDGRID_API_KEY (from secret ARN)
TWILIO_ACCOUNT_SID (from secret ARN)
TWILIO_AUTH_TOKEN (from secret ARN)
JWT_SECRET_KEY (from secret ARN)
```

## 🧪 Testing & Validation

### Local Testing
```bash
# Install dependencies
uv sync --dev

# Run tests
uv run pytest

# Start local server
uv run uvicorn main:app --reload --port 9000

# Build Lambda packages
./scripts/build-lambda-packages.sh
```

### API Testing
```bash
# Health check
curl https://api-gateway-url/health

# Send test email
curl -X POST https://api-gateway-url/api/emails/send \
  -H "Content-Type: application/json" \
  -d '{"to": "test@example.com", "subject": "Test", "body": "Hello"}'

# Check queue status
aws sqs get-queue-attributes \
  --queue-url $(terraform output -raw email_queue_url) \
  --attribute-names All
```

## 🚨 Troubleshooting

### Common Issues

#### Lambda Package Size
```bash
# Issue: Package too large (>50MB)
# Solution: Optimize dependencies
pip install --no-deps package-name
```

#### VPC Timeout
```bash
# Issue: Lambda timeout in VPC
# Solution: Check NAT Gateway and routes
aws ec2 describe-nat-gateways
```

#### Secrets Access Denied
```bash
# Issue: Cannot read secrets
# Solution: Verify IAM permissions
aws iam simulate-principal-policy \
  --policy-source-arn role-arn \
  --action-names secretsmanager:GetSecretValue \
  --resource-arns secret-arn
```

### Debug Commands
```bash
# View function logs
aws logs tail /aws/lambda/function-name --follow

# Test function directly
aws lambda invoke \
  --function-name function-name \
  --payload '{"test": "data"}' \
  response.json

# Check SQS messages
aws sqs receive-message \
  --queue-url queue-url \
  --max-number-of-messages 1
```

## 📋 Maintenance Tasks

### Regular Tasks
- **Monitor costs** via AWS Cost Explorer
- **Review logs** for errors and performance
- **Update dependencies** in Lambda packages
- **Rotate secrets** in Secrets Manager

### Scaling Adjustments
- **Adjust memory** for optimal cost/performance
- **Update timeout** based on processing needs
- **Modify concurrency** limits for cost control

## 🔄 Migration Guide

### From ECS to Lambda
1. Deploy Lambda infrastructure
2. Update CI/CD pipeline
3. Test parallel deployment
4. Switch DNS/traffic
5. Decommission ECS resources

### From Lambda to ECS
1. Deploy ECS infrastructure (use `emailsms-ecs/`)
2. Update CI/CD for container builds
3. Test ECS deployment
4. Update load balancer targets
5. Remove Lambda resources

## 📚 Related Documentation

- [CI/CD Pipeline](./.github/README.md)
- [API Documentation](./docs/)
- [Development Guide](./DEVELOPER_QUICK_REFERENCE.md)
- [ECS Alternative](../emailsms-ecs/)
