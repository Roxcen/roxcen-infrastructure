#!/bin/bash
# Development Environment Management Script
# Provides cost-effective start/stop functionality for Roxcen development environment

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
    echo "⏳ Waiting for database to become available (this may take 2-3 minutes)..."
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
        echo "💰 Environment is now consuming resources (~$0.80/day)"
    else
        echo "⚠️ Health check failed - may need more time to start"
        echo "🔄 Try checking again in 1-2 minutes"
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
    echo "✅ ECS service stopped (tasks scaling down)"
    
    # Stop RDS Database  
    echo "📊 Stopping RDS database..."
    aws rds stop-db-instance --db-instance-identifier $DB_INSTANCE --region $REGION
    echo "✅ Database stop initiated (will complete in 1-2 minutes)"
    echo "💰 Cost savings: ~$0.80/day while stopped"
    echo "ℹ️  Note: RDS will auto-restart after 7 days if left stopped"
}

function status_environment() {
    echo "📊 Development Environment Status Report"
    echo "========================================"
    
    # ECS Status
    ECS_INFO=$(aws ecs describe-services \
        --cluster $CLUSTER \
        --services $SERVICE \
        --region $REGION \
        --query 'services[0].{desired:desiredCount,running:runningCount,status:status}' \
        --output text)
    echo "🐳 ECS Service: $ECS_INFO"
    
    # RDS Status
    DB_STATUS=$(aws rds describe-db-instances \
        --db-instance-identifier $DB_INSTANCE \
        --region $REGION \
        --query 'DBInstances[0].DBInstanceStatus' \
        --output text)
    echo "📊 RDS Database: $DB_STATUS"
    
    # Health Check (if ECS running)
    DESIRED_COUNT=$(echo "$ECS_INFO" | awk '{print $1}')
    RUNNING_COUNT=$(echo "$ECS_INFO" | awk '{print $2}')
    
    if [ "$DESIRED_COUNT" = "1" ] && [ "$RUNNING_COUNT" = "1" ]; then
        echo "🧪 Checking API health..."
        if curl -f -s $API_ENDPOINT/health > /dev/null; then
            echo "🟢 API Health: HEALTHY"
            echo "🌐 Endpoint: $API_ENDPOINT/health"
        else
            echo "🔴 API Health: UNHEALTHY or STARTING"
        fi
    else
        echo "⚪ API Health: NOT RUNNING (ECS scaled to 0)"
    fi
    
    # Cost estimate
    if [ "$DESIRED_COUNT" = "1" ] && [ "$DB_STATUS" = "available" ]; then
        echo "💰 Current Status: RUNNING (~$0.80/day cost)"
    elif [ "$DESIRED_COUNT" = "0" ] && [ "$DB_STATUS" = "stopped" ]; then
        echo "💰 Current Status: STOPPED (~$0.25/day cost for ALB only)"
    else
        echo "💰 Current Status: MIXED (partial cost - check individual services)"
    fi
}

function quick_health_check() {
    echo "🩺 Quick Health Check"
    echo "===================="
    
    # Quick ECS check
    RUNNING_TASKS=$(aws ecs describe-services \
        --cluster $CLUSTER \
        --services $SERVICE \
        --region $REGION \
        --query 'services[0].runningCount' \
        --output text)
    
    if [ "$RUNNING_TASKS" = "1" ]; then
        echo "🐳 ECS: Running"
        if curl -f -s $API_ENDPOINT/health; then
            echo "✅ System: HEALTHY"
        else
            echo "⚠️ System: ECS running but API not responding"
        fi
    else
        echo "🛑 ECS: Stopped (scale to 1 to start)"
    fi
}

function show_usage() {
    echo "🔧 Development Environment Management"
    echo "===================================="
    echo "Usage: $0 {start|stop|status|health}"
    echo ""
    echo "Commands:"
    echo "  start   - Start development environment (ECS + RDS)"
    echo "  stop    - Stop development environment (saves ~$0.55/day)"
    echo "  status  - Show detailed environment status"
    echo "  health  - Quick health check"
    echo ""
    echo "Examples:"
    echo "  ./scripts/dev-environment.sh start    # Morning startup"
    echo "  ./scripts/dev-environment.sh stop     # Evening shutdown"
    echo "  ./scripts/dev-environment.sh status   # Full status report"
    echo "  ./scripts/dev-environment.sh health   # Quick check"
    echo ""
    echo "💡 Tip: Stop environment when not in use to save costs!"
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
    health)
        quick_health_check
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
