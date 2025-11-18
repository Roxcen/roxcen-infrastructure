# 🚀 Developer Quick Reference

## **Current System Status**
- 🏥 **API**: `http://roxcen-hms-api-development-2011897162.ap-south-1.elb.amazonaws.com/health`
- 💰 **Cost**: $28/month (71% optimized)
- 🔒 **Security**: Release-branch-only deployment

## **Quick Commands**

### **Deploy Application Changes**
```bash
# In webapi repository:
git checkout -b release/dev
git push origin release/dev
# ↳ Automatic deployment triggered
```

### **Deploy Infrastructure Changes**  
```bash
# In roxcen-infrastructure repository:
cd environments/webapi/dev
terraform plan && terraform apply
```

## 💻 **Local Development Setup**

### **Initial Local Setup (One-time):**
```bash
# Get AWS credentials and connection info
./scripts/get-local-credentials.sh

# Create .env file in webapi directory
cd ../webapi
cp .env.template .env

# Setup Python environment
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### **Daily Local Development:**
```bash
# 1. Start AWS resources
./scripts/dev-environment.sh start

# 2. Start local application (in webapi directory)
cd ../webapi
source venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# 3. Test endpoints
curl http://localhost:8000/health
curl http://localhost:8000/docs  # Swagger UI
```

### **Monitoring & Debugging:**
```bash
# View real-time CloudWatch logs
./scripts/monitor-cloudwatch.sh tail

# Check system health and metrics
./scripts/monitor-cloudwatch.sh health

# View recent errors
./scripts/monitor-cloudwatch.sh errors

# Complete system overview
./scripts/monitor-cloudwatch.sh all
```

## 💰 **Cost-Effective Development**

### **Daily Start/Stop Workflow:**
```bash
# Morning: Start development environment
./scripts/dev-environment.sh start

# Evening: Stop to save costs (saves ~$15-28/month)
./scripts/dev-environment.sh stop

# Quick status check
./scripts/dev-environment.sh status
```

### **Cost Savings:**
- **With Stop/Start**: $12-15/month (78% savings)
- **Always Running**: $28/month (71% savings) 
- **Original Estimate**: $99/month

💡 **Remember**: Always stop when not developing to maximize savings!

### **Health Checks**
```bash
# API health
curl -s http://roxcen-hms-api-development-2011897162.ap-south-1.elb.amazonaws.com/health | jq .

# ECS status
aws ecs describe-services --cluster roxcen-hms-api-cluster --services roxcen-hms-api-development --region ap-south-1 --query 'services[0].{status:status,runningCount:runningCount}'
```

## **Repository Map**

| Need to Change | Repository | Action |
|----------------|------------|--------|
| **Application code** | `webapi/` | Push to `release/dev` branch |
| **Infrastructure** | `roxcen-infrastructure/` | Run `terraform apply` |
| **Task definitions** | `webapi/.aws/` | Commit + release branch |
| **Environment config** | `roxcen-infrastructure/environments/` | Terraform apply |

## **Emergency Contacts**
- **Infrastructure**: `roxcen-infrastructure/` repository issues
- **Application**: `webapi/` repository issues  
- **Documentation**: All guides in `roxcen-infrastructure/`

## **Key URLs**
- **GitHub Infrastructure**: https://github.com/Roxcen/roxcen-infrastructure
- **GitHub WebAPI**: https://github.com/Roxcen/backend
- **AWS Console**: https://console.aws.amazon.com/ecs/home?region=ap-south-1

---
**📖 Full documentation**: See [README.md](./README.md)
