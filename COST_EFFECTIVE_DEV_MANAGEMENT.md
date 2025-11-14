# 💰 Cost-Effective Development Environment Management

## 🎯 **Automated Start/Stop for Development**

### **🔄 Daily Development Workflow (Cost Optimized)**

```bash
# Morning: Start development environment
./scripts/dev-environment.sh start

# Evening: Stop development environment  
./scripts/dev-environment.sh stop
```

### **💡 Cost Savings Potential:**
- **ECS Tasks**: $0 when stopped (pay only when running)
- **RDS Database**: ~$8/month savings with stop/start cycle
- **Total Daily Savings**: ~$0.80/day when stopped overnight
- **Monthly Savings**: ~$15-20 if stopped 16 hours daily

---

## 🗄️ **Database Management**

### **📊 RDS Instance Control:**

**Start Database:**
```bash
# Start RDS instance
aws rds start-db-instance --db-instance-identifier roxcen-development-db --region ap-south-1

# Wait for availability (2-3 minutes)
aws rds wait db-instance-available --db-instance-identifier roxcen-development-db --region ap-south-1

# Verify status
aws rds describe-db-instances --db-instance-identifier roxcen-development-db --region ap-south-1 --query 'DBInstances[0].{Status:DBInstanceStatus,Endpoint:Endpoint.Address}'
```

**Stop Database (Cost Savings):**
```bash
# Stop RDS instance (saves ~$8/month when stopped)
aws rds stop-db-instance --db-instance-identifier roxcen-development-db --region ap-south-1

# Verify stopped status
aws rds describe-db-instances --db-instance-identifier roxcen-development-db --region ap-south-1 --query 'DBInstances[0].DBInstanceStatus'
```

### **⚠️ Database Stop Limitations:**
- **Auto-restart**: RDS automatically restarts after 7 days
- **Data persistence**: All data remains intact during stop/start
- **Connection updates**: Application automatically reconnects when restarted
- **Backup schedule**: Continues during stop period

---

## 🚀 **ECS Service Management**

### **📊 Scale Down for Cost Savings:**

**Stop ECS Tasks (Scale to 0):**
```bash
# Scale development service to 0 tasks
aws ecs update-service \
  --cluster roxcen-hms-api-cluster \
  --service roxcen-hms-api-development \
  --desired-count 0 \
  --region ap-south-1

# Verify scaling
aws ecs describe-services \
  --cluster roxcen-hms-api-cluster \
  --services roxcen-hms-api-development \
  --region ap-south-1 \
  --query 'services[0].{desiredCount:desiredCount,runningCount:runningCount}'
```

**Start ECS Tasks (Scale to 1):**
```bash
# Scale development service to 1 task
aws ecs update-service \
  --cluster roxcen-hms-api-cluster \
  --service roxcen-hms-api-development \
  --desired-count 1 \
  --region ap-south-1

# Wait for service stability
aws ecs wait services-stable \
  --cluster roxcen-hms-api-cluster \
  --services roxcen-hms-api-development \
  --region ap-south-1

# Verify health
curl -f http://roxcen-hms-api-development-2011897162.ap-south-1.elb.amazonaws.com/health
```

---

## 🤖 **Automated Environment Management Script**

### **Create Complete Management Script:**

```bash
#!/bin/bash
# File: scripts/dev-environment.sh

set -e

REGION="ap-south-1"
CLUSTER="roxcen-hms-api-cluster"
SERVICE="roxcen-hms-api-development"
DB_INSTANCE="roxcen-development-db"
API_ENDPOINT="http://roxcen-hms-api-development-2011897162.ap-south-1.elb.amazonaws.com"

function start_environment() {
    echo "🚀 Starting development environment..."
    
    # Start RDS Database
    echo "📊 Starting RDS database..."
    aws rds start-db-instance --db-instance-identifier $DB_INSTANCE --region $REGION
    echo "⏳ Waiting for database to become available..."
    aws rds wait db-instance-available --db-instance-identifier $DB_INSTANCE --region $REGION
    echo "✅ Database started successfully"
    
    # Start ECS Service
    echo "🐳 Starting ECS service..."
    aws ecs update-service \
        --cluster $CLUSTER \
        --service $SERVICE \
        --desired-count 1 \
        --region $REGION > /dev/null
        
    echo "⏳ Waiting for service to become stable..."
    aws ecs wait services-stable \
        --cluster $CLUSTER \
        --services $SERVICE \
        --region $REGION
        
    # Health check
    echo "🧪 Performing health check..."
    sleep 30
    if curl -f -s $API_ENDPOINT/health > /dev/null; then
        echo "✅ Development environment is healthy!"
        echo "🌐 API available at: $API_ENDPOINT/health"
    else
        echo "⚠️ Health check failed - may need more time to start"
    fi
}

function stop_environment() {
    echo "🛑 Stopping development environment..."
    
    # Stop ECS Service
    echo "🐳 Stopping ECS service..."
    aws ecs update-service \
        --cluster $CLUSTER \
        --service $SERVICE \
        --desired-count 0 \
        --region $REGION > /dev/null
    echo "✅ ECS service stopped"
    
    # Stop RDS Database  
    echo "📊 Stopping RDS database..."
    aws rds stop-db-instance --db-instance-identifier $DB_INSTANCE --region $REGION
    echo "✅ Database stop initiated"
    echo "💰 Cost savings: ~$0.80/day while stopped"
}

function status_environment() {
    echo "📊 Development Environment Status:"
    
    # ECS Status
    ECS_STATUS=$(aws ecs describe-services \
        --cluster $CLUSTER \
        --services $SERVICE \
        --region $REGION \
        --query 'services[0].{desired:desiredCount,running:runningCount}' \
        --output text)
    echo "🐳 ECS Service: $ECS_STATUS tasks"
    
    # RDS Status
    DB_STATUS=$(aws rds describe-db-instances \
        --db-instance-identifier $DB_INSTANCE \
        --region $REGION \
        --query 'DBInstances[0].DBInstanceStatus' \
        --output text)
    echo "📊 RDS Database: $DB_STATUS"
    
    # Health Check (if running)
    if echo "$ECS_STATUS" | grep -q "1.*1"; then
        if curl -f -s $API_ENDPOINT/health > /dev/null; then
            echo "🟢 API Health: HEALTHY"
        else
            echo "🔴 API Health: UNHEALTHY"
        fi
    else
        echo "⚪ API Health: NOT RUNNING"
    fi
}

case "$1" in
    start)
        start_environment
        ;;
    stop)
        stop_environment
        ;;
    status)
        status_environment
        ;;
    *)
        echo "Usage: $0 {start|stop|status}"
        echo "  start  - Start development environment"
        echo "  stop   - Stop development environment (saves costs)"
        echo "  status - Check current environment status"
        exit 1
        ;;
esac
```

---

## 📅 **Scheduled Cost Management**

### **🕐 Automated Scheduling (Optional):**

**Using GitHub Actions Scheduled Workflows:**

```yaml
# .github/workflows/dev-environment-schedule.yml
name: Development Environment Scheduler

on:
  schedule:
    # Stop at 6 PM UTC (11:30 PM IST) - weekdays
    - cron: '0 18 * * 1-5'
    # Start at 6 AM UTC (11:30 AM IST) - weekdays  
    - cron: '0 6 * * 1-5'
  workflow_dispatch:
    inputs:
      action:
        description: 'Environment action'
        required: true
        type: choice
        options:
          - start
          - stop
          - status

jobs:
  manage-environment:
    runs-on: ubuntu-latest
    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ap-south-1

      - name: Stop environment (evening)
        if: github.event.schedule == '0 18 * * 1-5'
        run: |
          # Stop ECS service
          aws ecs update-service --cluster roxcen-hms-api-cluster --service roxcen-hms-api-development --desired-count 0 --region ap-south-1
          # Stop RDS database
          aws rds stop-db-instance --db-instance-identifier roxcen-development-db --region ap-south-1

      - name: Start environment (morning)
        if: github.event.schedule == '0 6 * * 1-5'
        run: |
          # Start RDS database
          aws rds start-db-instance --db-instance-identifier roxcen-development-db --region ap-south-1
          # Start ECS service  
          aws ecs update-service --cluster roxcen-hms-api-cluster --service roxcen-hms-api-development --desired-count 1 --region ap-south-1
```

---

## 💡 **Cost Management Best Practices**

### **🎯 Development Environment Optimization:**

1. **Daily Shutdown**: Stop environment when not in use (16 hours/day = ~50% savings)
2. **Weekend Shutdown**: Complete stop Friday evening to Monday morning
3. **RDS Management**: Stop database during extended non-usage periods
4. **Resource Monitoring**: Use CloudWatch to track actual usage patterns

### **📊 Cost Comparison:**

| Scenario | Monthly Cost | Savings |
|----------|-------------|---------|
| **24/7 Running** | $28/month | Baseline |
| **16h Daily Shutdown** | $15/month | **46% savings** |
| **Weekend + Night Shutdown** | $12/month | **57% savings** |
| **Extended Shutdown (2 weeks)** | $8/month | **71% savings** |

### **⚠️ Important Notes:**

- **RDS Auto-Start**: Database automatically restarts after 7 days of being stopped
- **Data Persistence**: All data (database, container images) persists during shutdown
- **Startup Time**: ~3-5 minutes for complete environment startup
- **Load Balancer**: ALB continues running (minimal cost ~$10/month) for instant access when scaled up

---

**💰 With proper start/stop management, you can reduce development costs to as low as $8-15/month!**
