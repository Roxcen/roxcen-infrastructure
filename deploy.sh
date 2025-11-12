#!/bin/bash

# Roxcen Infrastructure Deployment Script
# Usage: ./deploy.sh [shared|webapi-dev|webapi-prod] [plan|apply|destroy]

set -e

COMMAND=${1:-"shared"}
ACTION=${2:-"plan"}
TERRAFORM_DIR=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Set terraform directory based on command
case $COMMAND in
    "shared")
        TERRAFORM_DIR="."
        print_status "Working with shared infrastructure"
        ;;
    "webapi-dev")
        TERRAFORM_DIR="environments/webapi/dev"
        print_status "Working with WebAPI development environment"
        ;;
    "webapi-prod")
        TERRAFORM_DIR="environments/webapi/prod"
        print_status "Working with WebAPI production environment"
        ;;
    *)
        print_error "Invalid command. Use: shared, webapi-dev, or webapi-prod"
        exit 1
        ;;
esac

# Check if AWS credentials are configured
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    print_error "AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

print_success "AWS credentials verified"

# Navigate to terraform directory
cd $TERRAFORM_DIR

# Initialize terraform if needed
if [ ! -d ".terraform" ]; then
    print_status "Initializing Terraform..."
    terraform init
fi

# Validate terraform configuration
print_status "Validating Terraform configuration..."
terraform validate

# Execute the requested action
case $ACTION in
    "plan")
        print_status "Running Terraform plan..."
        terraform plan -out=tfplan
        print_success "Plan completed successfully"
        ;;
    "apply")
        print_status "Applying Terraform configuration..."
        if [ -f "tfplan" ]; then
            terraform apply tfplan
        else
            print_warning "No plan file found, running plan first..."
            terraform plan -out=tfplan
            terraform apply tfplan
        fi
        print_success "Apply completed successfully"
        
        # Show outputs
        print_status "Infrastructure outputs:"
        terraform output
        ;;
    "destroy")
        print_warning "This will destroy infrastructure. Are you sure? (y/N)"
        read -r confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            terraform destroy
            print_success "Destroy completed successfully"
        else
            print_status "Destroy cancelled"
        fi
        ;;
    *)
        print_error "Invalid action. Use: plan, apply, or destroy"
        exit 1
        ;;
esac

# Clean up plan file after apply
if [ "$ACTION" = "apply" ] && [ -f "tfplan" ]; then
    rm tfplan
fi

print_success "Deployment script completed"
