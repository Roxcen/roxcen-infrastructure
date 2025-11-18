#!/bin/bash
# File: scripts/get-local-credentials.sh
# Description: Fetch AWS credentials and connection info for local development

echo "🔐 Fetching AWS credentials for local development..."
echo "=================================================="

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &>/dev/null; then
    echo "❌ AWS CLI not configured or credentials invalid"
    echo "💡 Run: aws configure"
    exit 1
fi

echo "✅ AWS CLI configured successfully"
echo ""

# Get RDS connection details
echo "📊 RDS Connection Information:"
echo "-----------------------------"
RDS_INFO=$(aws rds describe-db-instances \
  --db-instance-identifier roxcen-development-db \
  --region ap-south-1 \
  --query 'DBInstances[0].{Endpoint:Endpoint.Address,Port:Endpoint.Port,Status:DBInstanceStatus,Engine:Engine}' \
  --output table 2>/dev/null)

if [ $? -eq 0 ]; then
    echo "$RDS_INFO"
else
    echo "❌ Could not fetch RDS information. Make sure the database exists and you have proper permissions."
    exit 1
fi

echo ""

# Get database URL from Secrets Manager
echo "🗄️ Database Connection String:"
echo "------------------------------"
DB_URL=$(aws secretsmanager get-secret-value \
  --secret-id "roxcen/development/database-url" \
  --region ap-south-1 \
  --query SecretString --output text 2>/dev/null)

if [ $? -eq 0 ]; then
    echo "DATABASE_URL=\"$DB_URL\""
else
    echo "❌ Could not fetch database URL from secrets manager"
    echo "💡 Make sure the secret 'roxcen/development/database-url' exists"
fi

echo ""

# Get JWT secret
echo "🔑 JWT Secret Key:"
echo "------------------"
JWT_SECRET=$(aws secretsmanager get-secret-value \
  --secret-id "roxcen/development/jwt-secret" \
  --region ap-south-1 \
  --query SecretString --output text 2>/dev/null)

if [ $? -eq 0 ]; then
    echo "JWT_SECRET_KEY=\"$JWT_SECRET\""
else
    echo "❌ Could not fetch JWT secret from secrets manager"
    echo "💡 Make sure the secret 'roxcen/development/jwt-secret' exists"
fi

echo ""

# Get current public IP for security group reference
echo "🌐 Your Current Public IP:"
echo "--------------------------"
MY_IP=$(curl -s https://checkip.amazonaws.com 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "Current IP: $MY_IP"
    echo "Security Group Rule (if needed): $MY_IP/32"
else
    echo "❌ Could not fetch public IP"
fi

echo ""

# Create .env template
echo "📁 Creating .env Template:"
echo "-------------------------"
cat > .env.template << EOF
# Database Configuration
DATABASE_URL="$DB_URL"

# JWT Configuration  
JWT_SECRET_KEY="$JWT_SECRET"

# API Configuration
API_V1_STR="/api/v1"
ENVIRONMENT="development"

# Email/SMS Configuration (optional for local dev)
EMAIL_QUEUE_URL="http://localhost:9000"
EMAIL_QUEUE_USERNAME="default_user"
EMAIL_QUEUE_PASSWORD="default_pass"

# reCAPTCHA Configuration (use test keys for local development)
RECAPTCHA_SECRET_KEY="6LeIxAcTAAAAAGG-vFI1TnRWxMZNFuojJ4WifJWe"

# Optional: Override any other settings for local development
# DEBUG=true
# LOG_LEVEL=debug
EOF

echo "✅ Created .env.template file"

echo ""
echo "🚀 Next Steps:"
echo "==============" 
echo "1. Copy template to .env file:"
echo "   cp .env.template .env"
echo ""
echo "2. Navigate to webapi directory:"
echo "   cd ../webapi"
echo ""
echo "3. Create virtual environment:"
echo "   python -m venv venv"
echo "   source venv/bin/activate"
echo ""
echo "4. Install dependencies:"
echo "   pip install -r requirements.txt"
echo ""
echo "5. Test database connection:"
echo "   python -c \"import os; from sqlalchemy import create_engine; from dotenv import load_dotenv; load_dotenv(); engine = create_engine(os.getenv('DATABASE_URL')); print('✅ Connected!' if engine.connect() else '❌ Failed')\""
echo ""
echo "6. Start local development:"
echo "   uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"
echo ""
echo "💡 Pro Tips:"
echo "- Use './scripts/dev-environment.sh start' to ensure AWS resources are running"
echo "- Monitor logs with './scripts/monitor-cloudwatch.sh logs'"
echo "- Test health endpoint: curl http://localhost:8000/health"
echo ""
echo "🔐 Security Note:"
echo "Never commit .env files to git - they're already in .gitignore"
