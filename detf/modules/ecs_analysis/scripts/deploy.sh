#!/bin/bash
# Django ECS Blue-Green Deployment Script

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}


# =============================================================================
# =============================================================================


# Function to check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        error "Terraform is not installed or not in PATH"
        exit 1
    fi
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        error "AWS CLI is not installed or not in PATH"
        exit 1
    fi
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        error "jq is not installed or not in PATH"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        error "AWS credentials not configured or invalid"
        exit 1
    fi
    
    success "Prerequisites check passed"
}

# Function to get current active environment
get_active_environment() {
    cd "$TERRAFORM_DIR"
    terraform output -raw active_environment 2>/dev/null || echo "blue"
}

# Function to get inactive environment
get_inactive_environment() {
    local active_env="$1"
    if [ "$active_env" = "blue" ]; then
        echo "green"
    else
        echo "blue"
    fi
}

# Function to build and push Docker image
build_and_push_image() {
    local version="$1"
    local environment="$2"
    
    log "Building Docker image for version $version..."
    
    cd "$TERRAFORM_DIR"
    local ecr_repo_url=$(terraform output -raw ecr_repository_url)
    local aws_region=$(terraform output -raw aws_region 2>/dev/null || echo "us-east-1")
    
    # Login to ECR
    aws ecr get-login-password --region "$aws_region" | docker login --username AWS --password-stdin "$ecr_repo_url"
    
    # Build image
    docker build -t "$ecr_repo_url:$version" \
        --build-arg ENVIRONMENT="$environment" \
        --build-arg VERSION="$version" \
        -f Dockerfile .
    
    # Tag as latest for the environment
    docker tag "$ecr_repo_url:$version" "$ecr_repo_url:$environment-latest"
    
    # Push images
    docker push "$ecr_repo_url:$version"
    docker push "$ecr_repo_url:$environment-latest"
    
    success "Docker image built and pushed successfully"
}

# Function to update ECS service
update_ecs_service() {
    local environment="$1"
    local version="$2"
    
    log "Updating ECS service for $environment environment..."
    
    cd "$TERRAFORM_DIR"
    local cluster_name=$(terraform output -raw ecs_cluster_name)
    local service_name=$(terraform output -raw "${environment}_service_name")
    
    # Update service with new task definition
    aws ecs update-service \
        --cluster "$cluster_name" \
        --service "$service_name" \
        --desired-count 2 \
        --force-new-deployment \
        > /dev/null
    
    success "ECS service updated for $environment environment"
}

# Function to wait for service stability
wait_for_service_stable() {
    local environment="$1"
    local timeout="${2:-600}"
    
    log "Waiting for $environment service to stabilize..."
    
    cd "$TERRAFORM_DIR"
    local cluster_name=$(terraform output -raw ecs_cluster_name)
    local service_name=$(terraform output -raw "${environment}_service_name")
    
    aws ecs wait services-stable \
        --cluster "$cluster_name" \
        --services "$service_name" \
        --cli-read-timeout "$timeout" \
        --cli-connect-timeout 60
    
    if [ $? -eq 0 ]; then
        success "$environment service is stable"
        return 0
    else
        error "$environment service failed to stabilize"
        return 1
    fi
}

# Function to check target group health
check_target_group_health() {
    local environment="$1"
    local timeout="${2:-300}"
    
    log "Checking health of $environment target group..."
    
    cd "$TERRAFORM_DIR"
    local tg_arn=$(terraform output -raw "${environment}_target_group_arn")
    
    local start_time=$(date +%s)
    local end_time=$((start_time + timeout))
    
    while [ $(date +%s) -lt $end_time ]; do
        local healthy_count=$(aws elbv2 describe-target-health \
            --target-group-arn "$tg_arn" \
            --query 'TargetHealthDescriptions[?TargetHealth.State==`healthy`] | length(@)' \
            --output text)
        
        local total_count=$(aws elbv2 describe-target-health \
            --target-group-arn "$tg_arn" \
            --query 'TargetHealthDescriptions | length(@)' \
            --output text)
        
        log "Health check: $healthy_count/$total_count targets healthy"
        
        if [ "$healthy_count" -gt 0 ] && [ "$healthy_count" -eq "$total_count" ]; then
            success "$environment environment is healthy"
            return 0
        fi
        
        sleep 15
    done
    
    error "Timeout waiting for $environment environment to become healthy"
    return 1
}

# Function to run health checks
run_health_checks() {
    local test_url="$1"
    local environment="$2"
    
    log "Running health checks for $environment environment..."
    
    # Test 1: Basic connectivity
    local http_status=$(curl -s -o /dev/null -w "%{http_code}" "$test_url/health/" || echo "000")
    if [ "$http_status" != "200" ]; then
        error "Health check failed: HTTP status $http_status"
        return 1
    fi
    
    # Test 2: Database connectivity
    local db_status=$(curl -s "$test_url/health/" | jq -r '.database // "unknown"' 2>/dev/null || echo "unknown")
    if [ "$db_status" != "ok" ]; then
        error "Database health check failed: $db_status"
        return 1
    fi
    
    # Test 3: Cache connectivity
    local cache_status=$(curl -s "$test_url/health/" | jq -r '.cache // "unknown"' 2>/dev/null || echo "unknown")
    if [ "$cache_status" != "ok" ]; then
        warning "Cache health check failed: $cache_status (continuing anyway)"
    fi
    
    success "Health checks passed for $environment environment"
    return 0
}

# Function to switch traffic
switch_traffic() {
    local new_active_env="$1"
    local listener_arn="$2"
    local target_group_arn="$3"
    
    log "Switching traffic to $new_active_env environment..."
    
    # Update the default action of the listener
    aws elbv2 modify-listener \
        --listener-arn "$listener_arn" \
        --default-actions Type=forward,TargetGroupArn="$target_group_arn" \
        > /dev/null
    
    success "Traffic switched to $new_active_env environment"
}

# Function to scale down environment
scale_down_environment() {
    local environment="$1"
    
    log "Scaling down $environment environment..."
    
    cd "$TERRAFORM_DIR"
    local cluster_name=$(terraform output -raw ecs_cluster_name)
    local service_name=$(terraform output -raw "${environment}_service_name")
    
    aws ecs update-service \
        --cluster "$cluster_name" \
        --service "$service_name" \
        --desired-count 0 \
        > /dev/null
    
    success "$environment environment scaled down"
}

# Function to rollback deployment
rollback() {
    local current_active="$1"
    local previous_active="$2"
    
    warning "Initiating rollback from $current_active to $previous_active..."
    
    cd "$TERRAFORM_DIR"
    
    # Get infrastructure details
    local listener_arn=$(terraform output -raw listener_arn)
    local previous_tg_arn=$(terraform output -raw "${previous_active}_target_group_arn")
    
    # Scale up previous environment
    update_ecs_service "$previous_active" "rollback"
    
    # Wait for service to stabilize
    if wait_for_service_stable "$previous_active" 600; then
        # Wait for health checks
        if check_target_group_health "$previous_active" 300; then
            # Switch traffic back
            switch_traffic "$previous_active" "$listener_arn" "$previous_tg_arn"
            
            # Scale down current environment
            scale_down_environment "$current_active"
            
            success "Rollback completed successfully"
        else
            error "Rollback failed - previous environment is not healthy"
            return 1
        fi
    else
        error "Rollback failed - previous environment did not stabilize"
        return 1
    fi
}

# Function to monitor deployment
monitor_deployment() {
    local environment="$1"
    local test_url="$2"
    local duration="${3:-300}"
    
    log "Monitoring $environment environment for $duration seconds..."
    
    local start_time=$(date +%s)
    local end_time=$((start_time + duration))
    local error_count=0
    local total_checks=0
    
    while [ $(date +%s) -lt $end_time ]; do
        total_checks=$((total_checks + 1))
        
        local http_status=$(curl -s -o /dev/null -w "%{http_code}" "$test_url" || echo "000")
        
        if [ "$http_status" != "200" ]; then
            error_count=$((error_count + 1))
            warning "Health check failed: HTTP $http_status (Error $error_count/$total_checks)"
        else
            log "Health check passed: HTTP $http_status"
        fi
        
        # Calculate error rate
        local error_rate=$((error_count * 100 / total_checks))
        
        # Check if error rate exceeds threshold (5%)
        if [ "$error_rate" -gt 5 ] && [ "$total_checks" -gt 10 ]; then
            error "Error rate ($error_rate%) exceeds threshold (5%)"
            return 1
        fi
        
        sleep 15
    done
    
    local final_error_rate=$((error_count * 100 / total_checks))
    log "Monitoring completed: $error_count errors out of $total_checks checks ($final_error_rate% error rate)"
    
    if [ "$final_error_rate" -le 5 ]; then
        success "Deployment monitoring passed"
        return 0
    else
        error "Deployment monitoring failed"
        return 1
    fi
}

# Main deployment function
deploy() {
    local new_version="$1"
    local skip_build="${2:-false}"
    local skip_tests="${3:-false}"
    
    log "Starting Django ECS blue-green deployment..."
    
    cd "$TERRAFORM_DIR"
    
    # Get current state
    local current_active=$(get_active_environment)
    local new_active=$(get_inactive_environment "$current_active")
    
    log "Current active environment: $current_active"
    log "Deploying to environment: $new_active"
    log "New version: $new_version"
    
    # Build and push Docker image if not skipping
    if [ "$skip_build" != "true" ]; then
        build_and_push_image "$new_version" "$new_active"
    fi
    
    # Update Terraform with new version
    log "Updating Terraform configuration..."
    terraform apply -auto-approve \
        -var="app_versions={\"$current_active\"=\"$(terraform output -json app_versions | jq -r ".$current_active")\",\"$new_active\"=\"$new_version\"}" \
        > /dev/null
    
    # Update ECS service
    update_ecs_service "$new_active" "$new_version"
    
    # Wait for service to stabilize
    if ! wait_for_service_stable "$new_active" 600; then
        error "New environment failed to stabilize"
        scale_down_environment "$new_active"
        return 1
    fi
    
    # Wait for target group health
    if ! check_target_group_health "$new_active" 600; then
        error "New environment failed health checks"
        scale_down_environment "$new_active"
        return 1
    fi
    
    # Run application health checks
    if [ "$skip_tests" != "true" ]; then
        local test_url=$(terraform output -raw "${new_active}_test_url")
        if ! run_health_checks "$test_url" "$new_active"; then
            error "Application health checks failed"
            scale_down_environment "$new_active"
            return 1
        fi
    fi
    
    # Switch traffic
    local listener_arn=$(terraform output -raw listener_arn)
    local new_tg_arn=$(terraform output -raw "${new_active}_target_group_arn")
    switch_traffic "$new_active" "$listener_arn" "$new_tg_arn"
    
    # Monitor deployment
    local production_url=$(terraform output -raw application_url)
    if ! monitor_deployment "$new_active" "$production_url" 300; then
        warning "Deployment monitoring failed, initiating rollback..."
        rollback "$new_active" "$current_active"
        return 1
    fi
    
    # Scale down old environment
    scale_down_environment "$current_active"
    
    # Update Terraform state
    terraform apply -auto-approve \
        -var="active_environment=$new_active" \
        > /dev/null
    
    success "Django ECS blue-green deployment completed successfully!"
    log "New active environment: $new_active"
    log "Application URL: $production_url"
}

# Function to show status
show_status() {
    cd "$TERRAFORM_DIR"
    
    local current_active=$(get_active_environment)
    local inactive_env=$(get_inactive_environment "$current_active")
    
    echo "=== Django ECS Deployment Status ==="
    echo "Active Environment: $current_active"
    echo "Inactive Environment: $inactive_env"
    echo ""
    
    # Get service status
    local cluster_name=$(terraform output -raw ecs_cluster_name)
    
    echo "Blue Environment Service:"
    aws ecs describe-services \
        --cluster "$cluster_name" \
        --services "$(terraform output -raw blue_service_name)" \
        --query 'services[0].[serviceName,status,runningCount,pendingCount,desiredCount]' \
        --output table
    
    echo ""
    echo "Green Environment Service:"
    aws ecs describe-services \
        --cluster "$cluster_name" \
        --services "$(terraform output -raw green_service_name)" \
        --query 'services[0].[serviceName,status,runningCount,pendingCount,desiredCount]' \
        --output table
    
    echo ""
    echo "Target Group Health:"
    local blue_tg_arn=$(terraform output -raw blue_target_group_arn)
    local green_tg_arn=$(terraform output -raw green_target_group_arn)
    
    echo "Blue Target Group:"
    aws elbv2 describe-target-health --target-group-arn "$blue_tg_arn" \
        --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State,TargetHealth.Description]' \
        --output table
    
    echo ""
    echo "Green Target Group:"
    aws elbv2 describe-target-health --target-group-arn "$green_tg_arn" \
        --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State,TargetHealth.Description]' \
        --output table
    
    echo ""
    echo "URLs:"
    echo "Production: $(terraform output -raw application_url)"
    echo "WWW: $(terraform output -raw www_url)"
    echo "Blue Test: $(terraform output -raw blue_test_url)"
    echo "Green Test: $(terraform output -raw green_test_url)"
    echo "CloudWatch Dashboard: $(terraform output -raw cloudwatch_dashboard_url)"
}

# Main script logic
case "${1:-}" in
    "deploy")
        check_prerequisites
        if [ -z "${2:-}" ]; then
            error "Version number required for deployment"
            echo "Usage: $0 deploy <version> [skip-build] [skip-tests]"
            exit 1
        fi
        deploy "$2" "${3:-false}" "${4:-false}"
        ;;
    "rollback")
        check_prerequisites
        current_active=$(get_active_environment)
        previous_active=$(get_inactive_environment "$current_active")
        rollback "$current_active" "$previous_active"
        ;;
    "status")
        show_status
        ;;
    "build")
        check_prerequisites
        if [ -z "${2:-}" ]; then
            error "Version number required for build"
            echo "Usage: $0 build <version> [environment]"
            exit 1
        fi
        build_and_push_image "$2" "${3:-blue}"
        ;;
    *)
        echo "Usage: $0 {deploy|rollback|status|build}"
        echo ""
        echo "Commands:"
        echo "  deploy <version> [skip-build] [skip-tests]  - Deploy new version to inactive environment"
        echo "  rollback                                     - Rollback to previous environment"
        echo "  status                                       - Show current deployment status"
        echo "  build <version> [environment]                - Build and push Docker image"
        echo ""
        echo "Examples:"
        echo "  $0 deploy v1.2.0"
        echo "  $0 deploy v1.2.0 skip-build"
        echo "  $0 deploy v1.2.0 false skip-tests"
        echo "  $0 rollback"
        echo "  $0 status"
        echo "  $0 build v1.2.0 blue"
        exit 1
        ;;
esac