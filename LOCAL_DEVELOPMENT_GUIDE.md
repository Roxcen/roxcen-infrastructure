# 💻 Local Development with AWS Resources

## 🗄️ **Database Connection from Local**

### **📊 Get RDS Connection Details:**

```bash
# Get RDS endpoint and connection info
aws rds describe-db-instances \
  --db-instance-identifier roxcen-development-db \
  --region ap-south-1 \
  --query 'DBInstances[0].{Endpoint:Endpoint.Address,Port:Endpoint.Port,Status:DBInstanceStatus}'

# Get database credentials from AWS Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id "roxcen/development/database-url" \
  --region ap-south-1 \
  --query SecretString --output text
```

### **🔐 Local Environment Variables:**

Create `.env` file in your local `webapi/` directory:

```bash
# File: webapi/.env
DATABASE_URL="postgresql://username:password@roxcen-development-db.cl04gyokuusm.ap-south-1.rds.amazonaws.com:5432/hospital_appointment?sslmode=require"
JWT_SECRET_KEY="your-jwt-secret-from-aws-secrets"
API_V1_STR="/api/v1"
ENVIRONMENT="development"

# Email/SMS Configuration (optional for local dev)
EMAIL_QUEUE_URL="http://localhost:9000"
EMAIL_QUEUE_USERNAME="default_user"
EMAIL_QUEUE_PASSWORD="default_pass"

# reCAPTCHA (use test keys for local)
RECAPTCHA_SECRET_KEY="6LeIxAcTAAAAAGG-vFI1TnRWxMZNFuojJ4WifJWe"
```

### **🛠️ Get Credentials Script:**

```bash
#!/bin/bash
# File: scripts/get-local-credentials.sh

echo "🔐 Fetching AWS credentials for local development..."

# Get RDS connection details
echo "📊 RDS Connection Info:"
aws rds describe-db-instances \
  --db-instance-identifier roxcen-development-db \
  --region ap-south-1 \
  --query 'DBInstances[0].{Endpoint:Endpoint.Address,Port:Endpoint.Port,Status:DBInstanceStatus}' \
  --output table

# Get database URL from Secrets Manager
echo "🗄️ Database URL:"
DB_URL=$(aws secretsmanager get-secret-value \
  --secret-id "roxcen/development/database-url" \
  --region ap-south-1 \
  --query SecretString --output text)
echo "DATABASE_URL=\"$DB_URL\""

# Get JWT secret
echo "🔑 JWT Secret:"
JWT_SECRET=$(aws secretsmanager get-secret-value \
  --secret-id "roxcen/development/jwt-secret" \
  --region ap-south-1 \
  --query SecretString --output text)
echo "JWT_SECRET_KEY=\"$JWT_SECRET\""

echo ""
echo "💡 Copy these values to your .env file for local development"
echo "📁 Create: webapi/.env with the above values"
```

---

## 🚀 **Local Development Setup**

### **1️⃣ Install Dependencies:**

```bash
# Navigate to webapi directory
cd /path/to/webapi

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On macOS/Linux
# or
venv\Scripts\activate     # On Windows

# Install dependencies
pip install -r requirements.txt

# Install development dependencies
pip install pytest pytest-cov black flake8 mypy
```

### **2️⃣ Setup Local Environment:**

```bash
# Get AWS credentials for local development
./scripts/get-local-credentials.sh > .env.example

# Copy and customize for your local setup
cp .env.example .env
# Edit .env with your preferred settings
```

### **3️⃣ Test Database Connection:**

```bash
# Test database connectivity
python -c "
import os
from sqlalchemy import create_engine
from dotenv import load_dotenv

load_dotenv()
engine = create_engine(os.getenv('DATABASE_URL'))
try:
    with engine.connect() as conn:
        result = conn.execute('SELECT version()')
        print('✅ Database connection successful!')
        print('📊 PostgreSQL version:', result.fetchone()[0])
except Exception as e:
    print('❌ Database connection failed:', e)
"
```

### **4️⃣ Run Application Locally:**

```bash
# Start the application
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

# Test health endpoint
curl http://localhost:8000/health

# Expected response:
# {"status":"healthy","message":"Roxcen HMS API is running","version":"1.0.0"}
```

---

## 📊 **CloudWatch Monitoring & Logs**

### **🔍 View ECS Application Logs:**

```bash
# List log streams for the application
aws logs describe-log-streams \
  --log-group-name "/ecs/roxcen-hms-api-dev" \
  --region ap-south-1 \
  --order-by LastEventTime \
  --descending \
  --max-items 5

# Get latest logs from current running container
LOG_STREAM=$(aws logs describe-log-streams \
  --log-group-name "/ecs/roxcen-hms-api-dev" \
  --region ap-south-1 \
  --order-by LastEventTime \
  --descending \
  --max-items 1 \
  --query 'logStreams[0].logStreamName' \
  --output text)

echo "📋 Latest log stream: $LOG_STREAM"

# View recent logs (last 10 minutes)
aws logs get-log-events \
  --log-group-name "/ecs/roxcen-hms-api-dev" \
  --log-stream-name "$LOG_STREAM" \
  --start-time $(date -d '10 minutes ago' +%s)000 \
  --region ap-south-1 \
  --query 'events[].message' \
  --output text
```

### **📈 CloudWatch Metrics Dashboard:**

```bash
# Get ECS service metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=roxcen-hms-api-development Name=ClusterName,Value=roxcen-hms-api-cluster \
  --start-time $(date -d '1 hour ago' --iso-8601) \
  --end-time $(date --iso-8601) \
  --period 300 \
  --statistics Average \
  --region ap-south-1

# Get RDS database metrics  
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name DatabaseConnections \
  --dimensions Name=DBInstanceIdentifier,Value=roxcen-development-db \
  --start-time $(date -d '1 hour ago' --iso-8601) \
  --end-time $(date --iso-8601) \
  --period 300 \
  --statistics Average \
  --region ap-south-1
```

### **🖥️ CloudWatch Console Links:**

```bash
# Generate CloudWatch console URLs
echo "📊 CloudWatch Resources:"
echo "ECS Logs: https://console.aws.amazon.com/cloudwatch/home?region=ap-south-1#logsV2:log-groups/log-group/$252Fecs$252Froxcen-hms-api-dev"
echo "ECS Metrics: https://console.aws.amazon.com/cloudwatch/home?region=ap-south-1#metricsV2:graph=~();query=AWS$252FECS;search=roxcen-hms-api"
echo "RDS Metrics: https://console.aws.amazon.com/cloudwatch/home?region=ap-south-1#metricsV2:graph=~();query=AWS$252FRDS;search=roxcen-development"
```

---

## 🛡️ **Security Considerations for Local Development**

### **🔐 AWS CLI Configuration:**

```bash
# Configure AWS CLI with your credentials
aws configure
# AWS Access Key ID: [Your access key]
# AWS Secret Access Key: [Your secret key]
# Default region name: ap-south-1
# Default output format: json

# Test AWS connectivity
aws sts get-caller-identity
aws rds describe-db-instances --region ap-south-1 --query 'DBInstances[].DBInstanceIdentifier'
```

### **🌐 Network Considerations:**

**Database Security Group:**
- RDS security group allows connections from ECS security group
- For local development, you may need to temporarily add your IP
- **⚠️ Security Warning**: Never open RDS to 0.0.0.0/0 in production

```bash
# Get your current public IP
MY_IP=$(curl -s https://checkip.amazonaws.com)/32

# Temporarily add your IP to RDS security group (if needed)
# Note: This should be done carefully and removed after development
```

### **🔒 Secrets Management:**

```bash
# Never commit .env files to git
echo ".env" >> .gitignore
echo ".env.*" >> .gitignore

# Use AWS Secrets Manager for sensitive data
# Store local development secrets separately from production
```

---

## 🧪 **Local Testing & Development Workflow**

### **📋 Development Checklist:**

1. **Environment Setup:**
   ```bash
   ✅ AWS CLI configured
   ✅ Database credentials obtained
   ✅ .env file created
   ✅ Dependencies installed
   ✅ Database connection tested
   ```

2. **Daily Development:**
   ```bash
   # Start development environment (if stopped)
   ./scripts/dev-environment.sh start
   
   # Start local application
   source venv/bin/activate
   uvicorn app.main:app --reload --port 8000
   
   # Test endpoints
   curl http://localhost:8000/health
   curl http://localhost:8000/docs  # Swagger UI
   ```

3. **Testing Against Cloud Resources:**
   ```bash
   # Run tests against development database
   pytest tests/ -v
   
   # Check logs for any issues
   aws logs tail /ecs/roxcen-hms-api-dev --follow --region ap-south-1
   ```

### **🔄 Hybrid Development (Local + Cloud):**

**Option 1: Local API + Cloud Database**
- ✅ Fast local development
- ✅ Real database with proper data
- ⚠️ Requires network access to RDS

**Option 2: Local Everything with Docker Compose**
- ✅ Completely offline development
- ✅ No AWS costs during development
- ⚠️ Different environment from production

**Option 3: Cloud Development Environment**
- ✅ Identical to production
- ✅ No local setup required
- ⚠️ Continuous AWS costs

---

## 📱 **CloudWatch Monitoring Script**

```bash
#!/bin/bash
# File: scripts/monitor-cloudwatch.sh

function show_recent_logs() {
    echo "📋 Recent Application Logs (last 30 minutes):"
    aws logs filter-log-events \
        --log-group-name "/ecs/roxcen-hms-api-dev" \
        --start-time $(date -d '30 minutes ago' +%s)000 \
        --region ap-south-1 \
        --query 'events[].[timestamp,message]' \
        --output table
}

function show_metrics() {
    echo "📊 Current System Metrics:"
    
    # CPU Utilization
    echo "🖥️ CPU Utilization (last hour average):"
    aws cloudwatch get-metric-statistics \
        --namespace AWS/ECS \
        --metric-name CPUUtilization \
        --dimensions Name=ServiceName,Value=roxcen-hms-api-development Name=ClusterName,Value=roxcen-hms-api-cluster \
        --start-time $(date -d '1 hour ago' --iso-8601) \
        --end-time $(date --iso-8601) \
        --period 3600 \
        --statistics Average \
        --region ap-south-1 \
        --query 'Datapoints[0].Average' \
        --output text
    
    # Memory Utilization
    echo "🧠 Memory Utilization (last hour average):"
    aws cloudwatch get-metric-statistics \
        --namespace AWS/ECS \
        --metric-name MemoryUtilization \
        --dimensions Name=ServiceName,Value=roxcen-hms-api-development Name=ClusterName,Value=roxcen-hms-api-cluster \
        --start-time $(date -d '1 hour ago' --iso-8601) \
        --end-time $(date --iso-8601) \
        --period 3600 \
        --statistics Average \
        --region ap-south-1 \
        --query 'Datapoints[0].Average' \
        --output text
    
    # Database Connections
    echo "🗄️ Database Connections (current):"
    aws cloudwatch get-metric-statistics \
        --namespace AWS/RDS \
        --metric-name DatabaseConnections \
        --dimensions Name=DBInstanceIdentifier,Value=roxcen-development-db \
        --start-time $(date -d '5 minutes ago' --iso-8601) \
        --end-time $(date --iso-8601) \
        --period 300 \
        --statistics Average \
        --region ap-south-1 \
        --query 'Datapoints[0].Average' \
        --output text
}

function show_errors() {
    echo "🚨 Recent Errors and Warnings:"
    aws logs filter-log-events \
        --log-group-name "/ecs/roxcen-hms-api-dev" \
        --filter-pattern "ERROR WARNING CRITICAL" \
        --start-time $(date -d '1 hour ago' +%s)000 \
        --region ap-south-1 \
        --query 'events[].[timestamp,message]' \
        --output table
}

case "$1" in
    logs)
        show_recent_logs
        ;;
    metrics)
        show_metrics
        ;;
    errors)
        show_errors
        ;;
    all)
        show_metrics
        echo ""
        show_recent_logs
        echo ""
        show_errors
        ;;
    *)
        echo "Usage: $0 {logs|metrics|errors|all}"
        echo "  logs    - Show recent application logs"
        echo "  metrics - Show system performance metrics"
        echo "  errors  - Show recent errors and warnings"
        echo "  all     - Show all monitoring information"
        ;;
esac
```

---

## 🎯 **Quick Local Development Commands**

```bash
# Get all credentials needed for local development
./scripts/get-local-credentials.sh

# Start AWS development environment
./scripts/dev-environment.sh start

# Monitor CloudWatch logs and metrics
./scripts/monitor-cloudwatch.sh all

# Check system health
./scripts/dev-environment.sh health

# Start local development
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

---

**💡 Pro Tips for Local Development:**

1. **Use Environment Variables**: Never hardcode AWS credentials
2. **Monitor Costs**: Use `./scripts/dev-environment.sh stop` when not developing
3. **Test Locally First**: Run tests locally before pushing to release branches
4. **Watch Logs**: Use CloudWatch to debug issues in the cloud environment
5. **Security**: Always use least-privilege IAM permissions for local development

**🎉 You're now ready for efficient local development with full AWS integration!**
