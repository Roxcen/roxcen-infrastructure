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
