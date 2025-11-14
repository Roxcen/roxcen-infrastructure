# 💰 **Cost Optimization Guide for Development Environment**

## **🏷️ Cost Breakdown & Optimizations**

### **Current Monthly Costs (~$90)**
- **NAT Gateway**: $45/month (2 gateways × $22.50)
- **Application Load Balancer**: $20/month
- **RDS db.t3.micro**: $15/month (free tier eligible)
- **ECS Fargate**: $10/month (512 CPU, 1GB RAM)

### **Optimized Monthly Costs (~$25)**
- **NAT Gateway**: $0/month ❌ **(REMOVED)**
- **Application Load Balancer**: $20/month ✅
- **RDS db.t3.micro**: $0/month ✅ **(FREE TIER)**
- **ECS Fargate**: $5/month ✅ **(AUTO-SHUTDOWN)**

---

## **🎯 Optimization Strategies Applied**

### **1. Remove NAT Gateways (-$45/month)**
- **Change**: Use public subnets for ECS tasks in development
- **Impact**: ECS tasks get public IPs directly (still secure with security groups)
- **Savings**: $45/month → $0/month

### **2. Auto-Shutdown Schedule (-$5/month)**
- **Script**: `scripts/cost-control.sh`
- **Schedule**: Stop services outside business hours (6 PM - 9 AM, weekends)
- **Savings**: ~50% runtime reduction = ~$5/month on ECS

### **3. RDS Free Tier Optimization (-$15/month)**
- **Settings**: 
  - No backups (backup_retention_period = 0)
  - No multi-AZ
  - No enhanced monitoring
  - No performance insights
- **Eligible**: 750 hours free per month (enough for development)

### **4. Minimal Storage & Compute**
- **ECS**: 512 CPU, 1GB RAM (minimum for FastAPI)
- **RDS**: 20GB storage, no auto-scaling
- **ALB**: Required for HTTPS/health checks (can't be optimized further)

---

## **🚀 Implementation Steps**

### **Step 1: Apply Current Optimizations**
```bash
# 1. Update ECS to use public subnets (already done)
cd environments/webapi/dev
terraform plan  # Check changes
terraform apply # Apply optimizations

# 2. Set up auto-shutdown
cd ../../../
./scripts/cost-control.sh  # Test the script
```

### **Step 2: Set Up Automated Cost Control**
```bash
# Option A: Cron job for automatic shutdown
echo "0 18 * * 1-5 /path/to/cost-control.sh stop" | crontab -
echo "0 9 * * 1-5 /path/to/cost-control.sh start" | crontab -

# Option B: Manual control
./scripts/cost-control.sh stop   # Stop when not needed
./scripts/cost-control.sh start  # Start when needed
```

### **Step 3: Monitor Costs**
```bash
# Check AWS Cost Explorer for:
# - EC2-ELB (Load Balancer): ~$20/month
# - ECS Fargate: <$10/month with auto-shutdown
# - RDS: $0 (free tier) + storage costs
```

---

## **💡 Additional Cost Saving Tips**

### **1. Development Best Practices**
- **Local Development**: Use Docker Compose locally when possible
- **Resource Cleanup**: Regularly destroy unused resources
- **Monitoring**: Set up billing alerts at $10, $25, $50

### **2. Extreme Cost Optimization (Optional)**
```bash
# Replace ALB with CloudFlare Tunnel (free)
# Use AWS Lambda instead of ECS (pay per request)
# Use DynamoDB free tier instead of RDS
# Use S3 static hosting for simple APIs
```

### **3. Free Tier Maximization**
- **ECS**: 500 CPU-hours, 1GB-hours free per month
- **RDS**: 750 hours db.t3.micro + 20GB storage free
- **ALB**: No free tier, but required for production-like setup
- **Data Transfer**: 1GB free per month

---

## **📊 Cost Comparison**

| Component | Original | Optimized | Savings |
|-----------|----------|-----------|---------|
| NAT Gateway | $45/month | $0/month | **$45** |
| RDS | $15/month | $0/month | **$15** |
| ECS (auto-shutdown) | $10/month | $5/month | **$5** |
| ALB | $20/month | $20/month | $0 |
| **TOTAL** | **$90/month** | **$25/month** | **$65/month (72% savings)** |

---

## **⚠️ Trade-offs for Development**

### **What You Lose:**
- **NAT Gateway**: ECS tasks have public IPs (still secure with security groups)
- **RDS Backups**: No automatic backups (acceptable for development)
- **Always-On**: Services stop outside business hours (manual override available)

### **What You Keep:**
- **Production-Like Architecture**: ALB, ECS, RDS structure remains the same
- **Security**: Security groups, private database, HTTPS capability
- **Scalability**: Easy to scale up for production
- **Monitoring**: CloudWatch logs and basic metrics

---

## **🎛️ Quick Commands**

```bash
# Stop everything (save money)
./scripts/cost-control.sh stop

# Start everything (resume work)
./scripts/cost-control.sh start

# Check current status
aws ecs describe-services --cluster roxcen-hms-api-cluster --services roxcen-hms-api-development --region ap-south-1

# Monitor costs
aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31 --granularity MONTHLY --metrics BlendedCost
```

---

## **🏆 Final Result**

**From $90/month → $25/month (72% cost reduction)**

Perfect for development while maintaining production readiness! 🎯
