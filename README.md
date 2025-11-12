# Roxcen Infrastructure Repository

This repository contains all infrastructure-as-code and deployment configurations for Roxcen applications.

## 🏗️ **Repository Structure**

```
roxcen-infrastructure/
├── applications/
│   ├── webapi/                 # Backend API infrastructure
│   │   ├── terraform/         # ECS, RDS, ALB configurations
│   │   ├── .github/           # CI/CD workflows
│   │   ├── .aws/              # Task definitions
│   │   ├── Dockerfile         # Container configuration
│   │   └── docker-compose.yml # Local development
│   └── frontend/              # Frontend infrastructure (future)
├── modules/                   # Reusable Terraform modules
│   ├── ecs-api/              # ECS API service module
│   ├── rds/                  # Database module
│   └── vpc/                  # Network module
├── environments/             # Environment configurations
│   ├── dev/                 # Development environment
│   ├── staging/             # Staging environment  
│   └── prod/                # Production environment
└── shared/                  # Shared resources
    ├── monitoring/          # CloudWatch, alerts
    ├── security/           # WAF, security groups
    └── networking/         # VPC, subnets, route tables
```

## 🚀 **Deployment Workflow**

### **Infrastructure First:**
1. Deploy infrastructure changes in this repository
2. Infrastructure deployment triggers application deployment
3. Application repositories contain only application code

### **Cross-Repository Integration:**
- Infrastructure outputs are shared via Terraform remote state
- GitHub Actions workflows trigger across repositories
- Configuration is centralized in this repository

## 🔧 **Getting Started**

### **Deploy WebAPI Infrastructure:**
```bash
cd applications/webapi/terraform/environments/dev
terraform init
terraform plan
terraform apply
```

### **Deploy Application:**
Infrastructure deployment automatically triggers application deployment in the webapi repository.

## 📋 **Repository Dependencies**

This repository manages infrastructure for:
- **webapi**: Backend API service
- **frontend**: React frontend (future)
- **emailsms**: Email/SMS service (future)

## 🔐 **Security & Access**

- Infrastructure team has write access to this repository  
- Application teams have read access for configuration
- Production deployments require approval workflows

---

**🎯 This separation allows for:**
- Clean application repositories focused on code
- Centralized infrastructure management  
- Better security and access control
- Easier infrastructure versioning and rollbacks
