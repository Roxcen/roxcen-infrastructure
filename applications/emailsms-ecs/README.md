# EmailSMS ECS Fargate Implementation

This directory contains the ECS Fargate infrastructure for the EmailSMS microservice as an alternative to the serverless Lambda implementation.

## 🚀 Overview

This implementation provides:
- **Always-on service** using ECS Fargate containers
- **Application Load Balancer** for high availability
- **Auto-scaling** based on CPU/Memory metrics
- **VPC networking** for secure communication
- **CloudWatch logging** and monitoring

## 🏗️ Architecture

```
Internet → ALB → ECS Fargate Tasks (Private Subnets) → RDS/Redis
```

### Components

1. **ECR Repository** - Container image storage
2. **ECS Cluster** - Container orchestration
3. **ECS Service** - Service management with auto-scaling
4. **Application Load Balancer** - Traffic distribution
5. **CloudWatch** - Logging and monitoring
6. **IAM Roles** - Security and permissions

## 📊 Resource Configuration

### Development Environment
- **CPU**: 256 units (0.25 vCPU)
- **Memory**: 512 MB
- **Desired Count**: 1 task
- **Auto-scaling**: 1-2 tasks

### Production Environment
- **CPU**: 512 units (0.5 vCPU)
- **Memory**: 1024 MB
- **Desired Count**: 2 tasks
- **Auto-scaling**: 2-10 tasks

## 💰 Cost Comparison

### ECS Fargate (Always-on)
- **Development**: ~$15-20/month
- **Production**: ~$50-80/month

### Lambda Serverless (Pay-per-use)
- **Development**: ~$1-5/month
- **Production**: ~$10-30/month

> **Recommendation**: Use Lambda serverless for EmailSMS as it's more cost-effective for sporadic workloads.

## 🚀 Deployment

```bash
# Deploy development
./deploy.sh development apply

# Deploy production
./deploy.sh production apply

# Destroy environment
./deploy.sh development destroy
```

## 📋 Configuration Files

- `main.tf` - Infrastructure definition
- `variables.tf` - Input variables
- `outputs.tf` - Output values
- `terraform-dev.tfvars` - Development configuration
- `terraform-prod.tfvars` - Production configuration

## 🔧 When to Use ECS Instead of Lambda

Consider ECS Fargate if you need:

1. **Persistent connections** (WebSockets, long-polling)
2. **Large containers** (>10GB)
3. **Consistent traffic** (cost-effective at scale)
4. **Complex networking** requirements
5. **Legacy applications** that can't be easily refactored

## 🔄 Migration from Lambda

If you need to migrate from Lambda to ECS:

1. Update CI/CD to build container images
2. Deploy ECS infrastructure
3. Update DNS to point to ALB
4. Monitor and optimize scaling policies

## 📚 Related Documentation

- [Lambda Implementation](../emailsms/) - Current serverless implementation
- [Deployment Guide](./deploy.sh)
- [Terraform Variables](./variables.tf)
