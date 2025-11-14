#!/bin/bash

# Auto-shutdown script for development environment cost optimization
# Run this script to stop ECS services and RDS instances outside business hours

set -e

echo "🏷️  Roxcen Development Environment Auto-Shutdown"
echo "================================================"

AWS_REGION="ap-south-1"
CLUSTER_NAME="roxcen-hms-api-cluster"
SERVICE_NAME="roxcen-hms-api-development"
DB_INSTANCE="roxcen-development-db"

# Function to check if it's business hours (9 AM - 6 PM IST, Mon-Fri)
is_business_hours() {
    current_hour=$(TZ='Asia/Kolkata' date '+%H')
    current_day=$(date '+%u')  # 1=Monday, 7=Sunday
    
    if [[ $current_day -le 5 && $current_hour -ge 9 && $current_hour -lt 18 ]]; then
        return 0  # Business hours
    else
        return 1  # Outside business hours
    fi
}

# Function to scale ECS service
scale_ecs_service() {
    local desired_count=$1
    echo "📊 Scaling ECS service to $desired_count tasks..."
    
    aws ecs update-service \
        --cluster "$CLUSTER_NAME" \
        --service "$SERVICE_NAME" \
        --desired-count "$desired_count" \
        --region "$AWS_REGION" > /dev/null
        
    echo "✅ ECS service scaled to $desired_count tasks"
}

# Function to stop/start RDS instance
manage_rds_instance() {
    local action=$1
    echo "🗄️  ${action}ing RDS instance..."
    
    if [[ $action == "stop" ]]; then
        aws rds stop-db-instance \
            --db-instance-identifier "$DB_INSTANCE" \
            --region "$AWS_REGION" > /dev/null 2>&1 || echo "⚠️  RDS instance may already be stopped"
    else
        aws rds start-db-instance \
            --db-instance-identifier "$DB_INSTANCE" \
            --region "$AWS_REGION" > /dev/null 2>&1 || echo "⚠️  RDS instance may already be running"
    fi
    
    echo "✅ RDS instance $action command sent"
}

# Main logic
if is_business_hours; then
    echo "🟢 Business hours detected - ensuring services are running"
    scale_ecs_service 1
    manage_rds_instance "start"
    echo ""
    echo "💰 Estimated hourly cost: ~$0.08 (ECS + RDS running)"
else
    echo "🔴 Outside business hours - shutting down to save costs"
    scale_ecs_service 0
    manage_rds_instance "stop"
    echo ""
    echo "💰 Estimated hourly cost: ~$0.01 (only ALB + storage)"
    echo "📅 Services will auto-start during business hours (9 AM - 6 PM IST, Mon-Fri)"
fi

echo ""
echo "🎯 To manually control:"
echo "   Start: ./cost-control.sh start"
echo "   Stop:  ./cost-control.sh stop"

# Manual override
if [[ $1 == "start" ]]; then
    echo "🚀 Manual start requested"
    scale_ecs_service 1
    manage_rds_instance "start"
elif [[ $1 == "stop" ]]; then
    echo "⏹️  Manual stop requested"
    scale_ecs_service 0
    manage_rds_instance "stop"
fi

echo "✨ Done!"
