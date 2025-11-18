#!/bin/bash
# File: scripts/monitor-cloudwatch.sh
# Description: Monitor CloudWatch logs and metrics for development environment

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

function check_aws_cli() {
    if ! aws sts get-caller-identity &>/dev/null; then
        echo -e "${RED}❌ AWS CLI not configured or credentials invalid${NC}"
        echo "💡 Run: aws configure"
        exit 1
    fi
}

function show_recent_logs() {
    echo -e "${BLUE}📋 Recent Application Logs (last 30 minutes):${NC}"
    echo "=============================================="
    
    # Get the most recent log stream
    LOG_STREAM=$(aws logs describe-log-streams \
        --log-group-name "/ecs/roxcen-hms-api-dev" \
        --region ap-south-1 \
        --order-by LastEventTime \
        --descending \
        --max-items 1 \
        --query 'logStreams[0].logStreamName' \
        --output text 2>/dev/null)
    
    if [ "$LOG_STREAM" == "None" ] || [ "$LOG_STREAM" == "" ]; then
        echo -e "${YELLOW}⚠️ No active log streams found. Is the application running?${NC}"
        return 1
    fi
    
    echo "📄 Latest log stream: $LOG_STREAM"
    echo ""
    
    # Show recent logs
    aws logs get-log-events \
        --log-group-name "/ecs/roxcen-hms-api-dev" \
        --log-stream-name "$LOG_STREAM" \
        --start-time $(date -d '30 minutes ago' +%s)000 \
        --region ap-south-1 \
        --query 'events[].[timestamp,message]' \
        --output table 2>/dev/null
        
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Error fetching logs${NC}"
    fi
}

function show_metrics() {
    echo -e "${GREEN}📊 System Performance Metrics:${NC}"
    echo "================================"
    
    # CPU Utilization
    echo -n "🖥️ CPU Utilization (last hour avg): "
    CPU_AVG=$(aws cloudwatch get-metric-statistics \
        --namespace AWS/ECS \
        --metric-name CPUUtilization \
        --dimensions Name=ServiceName,Value=roxcen-hms-api-development Name=ClusterName,Value=roxcen-hms-api-cluster \
        --start-time $(date -d '1 hour ago' --iso-8601) \
        --end-time $(date --iso-8601) \
        --period 3600 \
        --statistics Average \
        --region ap-south-1 \
        --query 'Datapoints[0].Average' \
        --output text 2>/dev/null)
    
    if [ "$CPU_AVG" != "None" ] && [ "$CPU_AVG" != "" ]; then
        printf "%.2f%%\n" "$CPU_AVG"
    else
        echo "No data available"
    fi
    
    # Memory Utilization
    echo -n "🧠 Memory Utilization (last hour avg): "
    MEM_AVG=$(aws cloudwatch get-metric-statistics \
        --namespace AWS/ECS \
        --metric-name MemoryUtilization \
        --dimensions Name=ServiceName,Value=roxcen-hms-api-development Name=ClusterName,Value=roxcen-hms-api-cluster \
        --start-time $(date -d '1 hour ago' --iso-8601) \
        --end-time $(date --iso-8601) \
        --period 3600 \
        --statistics Average \
        --region ap-south-1 \
        --query 'Datapoints[0].Average' \
        --output text 2>/dev/null)
    
    if [ "$MEM_AVG" != "None" ] && [ "$MEM_AVG" != "" ]; then
        printf "%.2f%%\n" "$MEM_AVG"
    else
        echo "No data available"
    fi
    
    # Database Connections
    echo -n "🗄️ Database Connections (current): "
    DB_CONN=$(aws cloudwatch get-metric-statistics \
        --namespace AWS/RDS \
        --metric-name DatabaseConnections \
        --dimensions Name=DBInstanceIdentifier,Value=roxcen-development-db \
        --start-time $(date -d '5 minutes ago' --iso-8601) \
        --end-time $(date --iso-8601) \
        --period 300 \
        --statistics Average \
        --region ap-south-1 \
        --query 'Datapoints[0].Average' \
        --output text 2>/dev/null)
    
    if [ "$DB_CONN" != "None" ] && [ "$DB_CONN" != "" ]; then
        printf "%.0f connections\n" "$DB_CONN"
    else
        echo "No data available"
    fi
    
    # Task Status
    echo -n "🔄 ECS Task Status: "
    TASK_STATUS=$(aws ecs describe-services \
        --cluster roxcen-hms-api-cluster \
        --services roxcen-hms-api-development \
        --region ap-south-1 \
        --query 'services[0].{running:runningCount,desired:desiredCount}' \
        --output text 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo "$TASK_STATUS"
    else
        echo "Service not found or not accessible"
    fi
}

function show_errors() {
    echo -e "${RED}🚨 Recent Errors and Warnings (last 2 hours):${NC}"
    echo "=============================================="
    
    # Look for error patterns in logs
    ERROR_LOGS=$(aws logs filter-log-events \
        --log-group-name "/ecs/roxcen-hms-api-dev" \
        --filter-pattern "ERROR WARNING CRITICAL Exception Traceback" \
        --start-time $(date -d '2 hours ago' +%s)000 \
        --region ap-south-1 \
        --query 'events[].[timestamp,message]' \
        --output table 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$ERROR_LOGS" ]; then
        echo "$ERROR_LOGS"
    else
        echo -e "${GREEN}✅ No errors found in recent logs${NC}"
    fi
}

function show_health_status() {
    echo -e "${BLUE}🏥 System Health Check:${NC}"
    echo "======================="
    
    # Check ECS Service Health
    echo "🔍 ECS Service Status:"
    aws ecs describe-services \
        --cluster roxcen-hms-api-cluster \
        --services roxcen-hms-api-development \
        --region ap-south-1 \
        --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount,Pending:pendingCount}' \
        --output table 2>/dev/null
    
    # Check RDS Status
    echo ""
    echo "🗄️ RDS Database Status:"
    aws rds describe-db-instances \
        --db-instance-identifier roxcen-development-db \
        --region ap-south-1 \
        --query 'DBInstances[0].{Status:DBInstanceStatus,Engine:Engine,Class:DBInstanceClass,MultiAZ:MultiAZ}' \
        --output table 2>/dev/null
    
    # Check Load Balancer Health
    echo ""
    echo "⚖️ Load Balancer Target Health:"
    TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups \
        --region ap-south-1 \
        --query 'TargetGroups[?contains(TargetGroupName, `roxcen-hms-api-dev`)].TargetGroupArn' \
        --output text 2>/dev/null)
    
    if [ -n "$TARGET_GROUP_ARN" ]; then
        aws elbv2 describe-target-health \
            --target-group-arn "$TARGET_GROUP_ARN" \
            --region ap-south-1 \
            --query 'TargetHealthDescriptions[].[Target.Id,TargetHealth.State,TargetHealth.Description]' \
            --output table 2>/dev/null
    else
        echo "Target group not found"
    fi
}

function tail_logs() {
    echo -e "${BLUE}📋 Tailing Application Logs (Press Ctrl+C to stop):${NC}"
    echo "=================================================="
    
    aws logs tail /ecs/roxcen-hms-api-dev --follow --region ap-south-1
}

function show_cost_metrics() {
    echo -e "${YELLOW}💰 Cost and Resource Usage:${NC}"
    echo "============================"
    
    # Show current running resources
    echo "📊 Currently Running Resources:"
    echo "- ECS Tasks: $(aws ecs describe-services --cluster roxcen-hms-api-cluster --services roxcen-hms-api-development --region ap-south-1 --query 'services[0].runningCount' --output text 2>/dev/null || echo 'Unknown')"
    echo "- RDS Status: $(aws rds describe-db-instances --db-instance-identifier roxcen-development-db --region ap-south-1 --query 'DBInstances[0].DBInstanceStatus' --output text 2>/dev/null || echo 'Unknown')"
    
    echo ""
    echo "💡 Cost Optimization Tips:"
    echo "- Use './scripts/dev-environment.sh stop' when not developing"
    echo "- RDS stopped saves ~$13/month"
    echo "- ECS with 0 tasks saves ~$15/month"
    echo "- Total potential savings: ~$15-28/month when stopped"
}

# Help function
function show_help() {
    echo "CloudWatch Monitoring Script"
    echo "=========================="
    echo "Usage: $0 {logs|metrics|errors|health|tail|cost|all|help}"
    echo ""
    echo "Commands:"
    echo "  logs     - Show recent application logs (last 30 minutes)"
    echo "  metrics  - Show system performance metrics"
    echo "  errors   - Show recent errors and warnings"  
    echo "  health   - Show comprehensive system health status"
    echo "  tail     - Tail logs in real-time (Ctrl+C to stop)"
    echo "  cost     - Show cost and resource usage information"
    echo "  all      - Show all monitoring information"
    echo "  help     - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 logs           # Quick log check"
    echo "  $0 health         # Full health status"
    echo "  $0 tail           # Real-time log monitoring"
    echo "  $0 all            # Complete system overview"
}

# Main script logic
check_aws_cli

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
    health)
        show_health_status
        ;;
    tail)
        tail_logs
        ;;
    cost)
        show_cost_metrics
        ;;
    all)
        show_metrics
        echo ""
        show_health_status
        echo ""
        show_recent_logs
        echo ""
        show_errors
        echo ""
        show_cost_metrics
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}❌ Invalid command: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
