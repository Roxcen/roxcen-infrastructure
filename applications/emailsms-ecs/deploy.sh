#!/bin/bash

# Deploy EmailSMS Microservice Infrastructure
# Usage: ./deploy.sh [environment] [action]
# Example: ./deploy.sh development plan
# Example: ./deploy.sh production apply

set -e

ENVIRONMENT=${1:-development}
ACTION=${2:-plan}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(development|production)$ ]]; then
    echo "❌ Error: Environment must be 'development' or 'production'"
    echo "Usage: $0 [development|production] [plan|apply|destroy]"
    exit 1
fi

# Validate action
if [[ ! "$ACTION" =~ ^(plan|apply|destroy|init|refresh|import|output)$ ]]; then
    echo "❌ Error: Action must be one of: plan, apply, destroy, init, refresh, import, output"
    echo "Usage: $0 [development|production] [plan|apply|destroy|init|refresh|import|output]"
    exit 1
fi

echo "🚀 EmailSMS Infrastructure Deployment"
echo "Environment: $ENVIRONMENT"
echo "Action: $ACTION"
echo "Directory: $SCRIPT_DIR"
echo

# Check for required tools
command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform is required but not installed. Aborting." >&2; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI is required but not installed. Aborting." >&2; exit 1; }

# Check AWS credentials
aws sts get-caller-identity >/dev/null 2>&1 || { echo "❌ AWS credentials not configured. Please run 'aws configure' first." >&2; exit 1; }

# Set Terraform workspace
cd "$SCRIPT_DIR"

# Initialize Terraform (always safe to run)
echo "🔧 Initializing Terraform..."
terraform init

# Select or create workspace
echo "🔄 Setting Terraform workspace to: $ENVIRONMENT"
terraform workspace select "$ENVIRONMENT" 2>/dev/null || terraform workspace new "$ENVIRONMENT"

# Set variables file
VARS_FILE="terraform-${ENVIRONMENT}.tfvars"

if [[ ! -f "$VARS_FILE" ]]; then
    echo "❌ Error: Variables file '$VARS_FILE' not found"
    echo "Please create '$VARS_FILE' with appropriate configuration"
    exit 1
fi

echo "📁 Using variables file: $VARS_FILE"

# Execute Terraform action
case $ACTION in
    "init")
        echo "✅ Terraform already initialized"
        ;;
    "plan")
        echo "📋 Running Terraform plan..."
        terraform plan -var-file="$VARS_FILE" -out="tfplan-${ENVIRONMENT}"
        echo "✅ Plan completed. Review the changes above."
        echo "💡 To apply these changes, run: $0 $ENVIRONMENT apply"
        ;;
    "apply")
        if [[ -f "tfplan-${ENVIRONMENT}" ]]; then
            echo "🚀 Applying Terraform plan..."
            terraform apply "tfplan-${ENVIRONMENT}"
            rm -f "tfplan-${ENVIRONMENT}"
        else
            echo "🚀 Running Terraform apply..."
            terraform apply -var-file="$VARS_FILE" -auto-approve
        fi
        
        echo "✅ Deployment completed!"
        echo
        echo "📊 Infrastructure Summary:"
        terraform output -json | jq -r '
            to_entries[] | 
            "• \(.key): \(.value.value)"
        ' 2>/dev/null || terraform output
        ;;
    "destroy")
        echo "⚠️  WARNING: This will destroy all infrastructure for $ENVIRONMENT environment"
        echo "Are you sure? Type 'yes' to continue:"
        read -r confirmation
        if [[ "$confirmation" == "yes" ]]; then
            echo "🗑️  Destroying infrastructure..."
            terraform destroy -var-file="$VARS_FILE" -auto-approve
            echo "✅ Infrastructure destroyed"
        else
            echo "❌ Destruction cancelled"
        fi
        ;;
    "refresh")
        echo "🔄 Refreshing Terraform state..."
        terraform refresh -var-file="$VARS_FILE"
        ;;
    "output")
        echo "📊 Terraform outputs:"
        terraform output
        ;;
    "import")
        echo "📥 Import mode - please specify resource:"
        echo "Usage: terraform import -var-file=\"$VARS_FILE\" <resource_type.resource_name> <resource_id>"
        ;;
esac

echo
echo "🏁 Operation completed successfully!"

# Show helpful information based on environment
if [[ "$ACTION" == "apply" ]]; then
    echo
    echo "🔗 Useful Commands:"
    echo "• View logs: aws logs tail /aws/ecs/roxcen-emailsms-${ENVIRONMENT}/app --follow"
    echo "• ECS service status: aws ecs describe-services --cluster roxcen-emailsms-${ENVIRONMENT} --services roxcen-emailsms-${ENVIRONMENT}"
    echo "• Update service: aws ecs update-service --cluster roxcen-emailsms-${ENVIRONMENT} --service roxcen-emailsms-${ENVIRONMENT} --force-new-deployment"
    
    if [[ "$ENVIRONMENT" == "development" ]]; then
        echo "• Development URL: Check the load_balancer_dns output above"
    else
        echo "• Production URL: https://emailsms-api.roxcen.com"
    fi
fi
