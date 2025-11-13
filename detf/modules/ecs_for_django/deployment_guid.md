# Django ECS Deployment Guide with Blue-Green Strategy

-   <details><summary style="font-size:25px;color:Orange">Table of Contents</summary>

    1. [Overview](#overview)
    2. [Architecture](#architecture)
    3. [Prerequisites](#prerequisites)
    4. [Initial Setup](#initial-setup)
    5. [Django Application Preparation](#django-application-preparation)
    6. [Infrastructure Deployment](#infrastructure-deployment)
    7. [Application Deployment](#application-deployment)
    8. [Blue-Green Deployment Process](#blue-green-deployment-process)
    9. [Monitoring and Troubleshooting](#monitoring-and-troubleshooting)
    10. [Security Best Practices](#security-best-practices)
    11. [Cost Optimization](#cost-optimization)
    12. [Advanced Scenarios](#advanced-scenarios)

    </details>

---

-   <details><summary style="font-size:25px;color:Orange">Overview</summary>

    This guide provides a comprehensive solution for deploying Django applications on AWS ECS with Blue-Green deployment capabilities. The infrastructure is designed for production use with security, scalability, and cost optimization in mind.

    ### Key Features

    -   **Zero-downtime deployments** with Blue-Green strategy
    -   **Auto-scaling ECS services** with EC2 launch type
    -   **Secure database** with RDS PostgreSQL and encryption
    -   **Redis caching** with ElastiCache
    -   **Static/Media files** served via CloudFront and S3
    -   **Comprehensive monitoring** with CloudWatch
    -   **Secrets management** with AWS Secrets Manager
    -   **SSL/TLS termination** at the load balancer

    </details>

---

-   <details><summary style="font-size:25px;color:Orange">Architecture</summary>

    ### High-Level Architecture

    ```
    Internet → Route53 → ALB → ECS Services (Blue/Green) → RDS PostgreSQL
                        ↓
                    CloudFront → S3 (Static/Media)
                        ↓
                    ElastiCache Redis
    ```

    ### Component Overview

    -   **ECS Cluster**: Manages containerized Django applications
    -   **Application Load Balancer**: Routes traffic between Blue/Green environments
    -   **RDS PostgreSQL**: Primary database with encryption and backups
    -   **ElastiCache Redis**: Session storage and caching
    -   **S3 + CloudFront**: Static and media file serving
    -   **ECR**: Docker image repository
    -   **Secrets Manager**: Secure credential storage
    -   **CloudWatch**: Monitoring and logging

    </details>

---

-   <details><summary style="font-size:25px;color:Orange">Prerequisites</summary>

    ### Required Tools

    ```bash
    # Install required tools
    # macOS
    brew install terraform awscli docker jq

    # Ubuntu/Debian
    sudo apt-get update
    sudo apt-get install terraform awscli docker.io jq

    # Amazon Linux
    sudo yum install terraform awscli docker jq
    ```

    ### AWS Permissions

    Ensure your AWS user/role has permissions for:

    -   ECS (clusters, services, tasks)
    -   EC2 (instances, security groups, load balancers)
    -   RDS (databases, subnet groups)
    -   ElastiCache (replication groups)
    -   ECR (repositories)
    -   S3 (buckets, objects)
    -   CloudFront (distributions)
    -   Route53 (hosted zones, records)
    -   Secrets Manager
    -   IAM (roles, policies)
    -   CloudWatch (logs, metrics, dashboards)

    ### Existing Infrastructure Requirements

    -   VPC with public and private subnets
    -   SSL certificate in ACM
    -   Route53 hosted zone
    -   EC2 key pair for SSH access

    </details>

---

-   <details><summary style="font-size:25px;color:Orange">Initial Setup</summary>

    ### Step 1: Clone and Configure

    ```bash
    # Create project directory
    mkdir django-ecs-deployment
    cd django-ecs-deployment

    # Copy Terraform files (from the provided configuration)
    # Copy terraform.tfvars.example to terraform.tfvars
    cp terraform.tfvars.example terraform.tfvars
    ```

    ### Step 2: Update terraform.tfvars

    ```hcl
    # terraform.tfvars
    aws_region = "us-east-1"
    project_name = "django-app"

    # Replace with your actual values
    existing_vpc_id = "vpc-xxxxxxxxx"
    certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxxxxxxx"
    domain_name     = "harnesstech.com"
    key_pair_name   = "your-key-pair"

    # Database Configuration
    db_name           = "djangodb"
    db_username       = "djangouser"
    db_instance_class = "db.t3.micro"

    # ECS Configuration
    ecs_instance_type     = "t3.small"
    service_desired_count = 2

    # Application versions
    app_versions = {
    blue  = "v1.0.0"
    green = "v1.1.0"
    }
    ```

    ### Step 3: Initialize Terraform

    ```bash
    # Initialize Terraform
    terraform init

    # Validate configuration
    terraform validate

    # Plan deployment
    terraform plan

    # Apply configuration
    terraform apply
    ```

    </details>

---

-   <details><summary style="font-size:25px;color:Orange">Django Application Preparation</summary>

    ### Step 1: Create Django Project Structure

    ```bash
    # Create Django project
    mkdir django-app
    cd django-app

    # Create virtual environment
    python -m venv venv
    source venv/bin/activate  # On Windows: venv\Scripts\activate

    # Install Django and dependencies
    pip install django psycopg2-binary redis boto3 django-storages gunicorn
    ```

    ### Step 2: Django Settings Configuration

    Create `myproject/settings/production.py`:

    ```python
    # myproject/settings/production.py
    import os
    import json
    from .base import *

    # Security
    DEBUG = False
    SECRET_KEY = os.environ.get('SECRET_KEY')
    ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', '').split(',')

    # Database
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.postgresql',
            'NAME': os.environ.get('DB_NAME'),
            'USER': os.environ.get('DB_USER'),
            'PASSWORD': os.environ.get('DB_PASSWORD'),
            'HOST': os.environ.get('DB_HOST'),
            'PORT': '5432',
            'OPTIONS': {
                'sslmode': 'require',
            },
        }
    }

    # Cache
    CACHES = {
        'default': {
            'BACKEND': 'django_redis.cache.RedisCache',
            'LOCATION': os.environ.get('REDIS_URL'),
            'OPTIONS': {
                'CLIENT_CLASS': 'django_redis.client.DefaultClient',
            }
        }
    }

    # Static files (CSS, JavaScript, Images)
    AWS_ACCESS_KEY_ID = None  # Use IAM roles
    AWS_SECRET_ACCESS_KEY = None  # Use IAM roles
    AWS_STORAGE_BUCKET_NAME_STATIC = os.environ.get('AWS_STORAGE_BUCKET_NAME_STATIC')
    AWS_STORAGE_BUCKET_NAME_MEDIA = os.environ.get('AWS_STORAGE_BUCKET_NAME_MEDIA')
    AWS_S3_REGION_NAME = os.environ.get('AWS_DEFAULT_REGION', 'us-east-1')
    AWS_S3_CUSTOM_DOMAIN_STATIC = os.environ.get('CLOUDFRONT_STATIC_DOMAIN')
    AWS_S3_CUSTOM_DOMAIN_MEDIA = os.environ.get('CLOUDFRONT_MEDIA_DOMAIN')

    # Static files configuration
    STATICFILES_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'
    DEFAULT_FILE_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'

    STATIC_URL = os.environ.get('STATIC_URL', '/static/')
    MEDIA_URL = os.environ.get('MEDIA_URL', '/media/')

    # Security settings
    SECURE_BROWSER_XSS_FILTER = True
    SECURE_CONTENT_TYPE_NOSNIFF = True
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_SECONDS = 31536000
    SECURE_REDIRECT_EXEMPT = []
    SECURE_SSL_REDIRECT = True
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True

    # Logging
    LOGGING = {
        'version': 1,
        'disable_existing_loggers': False,
        'formatters': {
            'verbose': {
                'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
                'style': '{',
            },
        },
        'handlers': {
            'console': {
                'class': 'logging.StreamHandler',
                'formatter': 'verbose',
            },
        },
        'root': {
            'handlers': ['console'],
            'level': 'INFO',
        },
        'loggers': {
            'django': {
                'handlers': ['console'],
                'level': 'INFO',
                'propagate': False,
            },
        },
    }
    ```

    ### Step 3: Create Health Check View

    Create `myproject/health/views.py`:

    ```python
    # myproject/health/views.py
    import json
    from django.http import JsonResponse
    from django.db import connection
    from django.core.cache import cache
    from django.conf import settings

    def health_check(request):
        """Health check endpoint for load balancer"""
        health_status = {
            'status': 'healthy',
            'environment': getattr(settings, 'ENVIRONMENT', 'unknown'),
            'version': getattr(settings, 'VERSION', 'unknown'),
        }

        # Check database connectivity
        try:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
            health_status['database'] = 'ok'
        except Exception as e:
            health_status['database'] = 'error'
            health_status['database_error'] = str(e)
            health_status['status'] = 'unhealthy'

        # Check cache connectivity
        try:
            cache.set('health_check', 'ok', 30)
            cache_result = cache.get('health_check')
            if cache_result == 'ok':
                health_status['cache'] = 'ok'
            else:
                health_status['cache'] = 'error'
        except Exception as e:
            health_status['cache'] = 'error'
            health_status['cache_error'] = str(e)

        status_code = 200 if health_status['status'] == 'healthy' else 503
        return JsonResponse(health_status, status=status_code)
    ```

    Add to `myproject/urls.py`:

    ```python
    # myproject/urls.py
    from django.contrib import admin
    from django.urls import path, include
    from myproject.health.views import health_check

    urlpatterns = [
        path('admin/', admin.site.urls),
        path('health/', health_check, name='health_check'),
        # Add your app URLs here
    ]
    ```

    ### Step 4: Create Dockerfile

    ```dockerfile
    # Dockerfile
    FROM python:3.11-slim

    # Set environment variables
    ENV PYTHONDONTWRITEBYTECODE=1
    ENV PYTHONUNBUFFERED=1
    ENV DEBIAN_FRONTEND=noninteractive

    # Install system dependencies
    RUN apt-get update \
        && apt-get install -y --no-install-recommends \
            postgresql-client \
            curl \
            gcc \
            libc6-dev \
            libpq-dev \
        && rm -rf /var/lib/apt/lists/*

    # Set work directory
    WORKDIR /app

    # Install Python dependencies
    COPY requirements.txt /app/
    RUN pip install --no-cache-dir -r requirements.txt

    # Copy project
    COPY . /app/

    # Create non-root user
    RUN adduser --disabled-password --gecos '' appuser \
        && chown -R appuser:appuser /app
    USER appuser

    # Collect static files
    RUN python manage.py collectstatic --noinput --settings=myproject.settings.production

    # Expose port
    EXPOSE 8000

    # Health check
    HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
        CMD curl -f http://localhost:8000/health/ || exit 1

    # Run gunicorn
    CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "3", "--timeout", "60", "--keep-alive", "2", "--max-requests", "1000", "--max-requests-jitter", "100", "myproject.wsgi:application"]
    ```

    ### Step 5: Create requirements.txt

    ```txt
    # requirements.txt
    Django==4.2.7
    psycopg2-binary==2.9.7
    redis==4.6.0
    django-redis==5.3.0
    boto3==1.29.7
    django-storages==1.14.2
    gunicorn==21.2.0
    ```

    ### Step 6: Create Docker Compose for Local Development

    ```yaml
    # docker-compose.yml
    version: "3.8"

    services:
        web:
            build: .
            ports:
                - "8000:8000"
            environment:
                - DEBUG=True
                - SECRET_KEY=your-local-secret-key
                - DB_NAME=djangodb
                - DB_USER=postgres
                - DB_PASSWORD=postgres
                - DB_HOST=db
                - REDIS_URL=redis://redis:6379/0
                - ALLOWED_HOSTS=localhost,127.0.0.1
            depends_on:
                - db
                - redis
            volumes:
                - .:/app

        db:
            image: postgres:15
            environment:
                - POSTGRES_DB=djangodb
                - POSTGRES_USER=postgres
                - POSTGRES_PASSWORD=postgres
            volumes:
                - postgres_data:/var/lib/postgresql/data

        redis:
            image: redis:7-alpine
            ports:
                - "6379:6379"

    volumes:
        postgres_data:
    ```

    </details>

---

-   <details><summary style="font-size:25px;color:Orange">Infrastructure Deployment</summary>

    ### Step 1: Deploy Infrastructure

    ```bash
    # Navigate to terraform directory
    cd django-ecs-deployment

    # Initialize and apply
    terraform init
    terraform apply
    ```

    ### Step 2: Verify Infrastructure

    ```bash
    # Check outputs
    terraform output

    # Verify ECS cluster
    aws ecs describe-clusters --clusters $(terraform output -raw ecs_cluster_name)

    # Check RDS instance
    aws rds describe-db-instances --db-instance-identifier $(terraform output -raw db_instance_id)

    # Verify ECR repository
    aws ecr describe-repositories --repository-names $(terraform output -raw ecr_repository_name)
    ```

    </details>

---

-   <details><summary style="font-size:25px;color:Orange">Application Deployment</summary>

    ### Step 1: Build and Push Initial Image

    ```bash
    # Get ECR repository URL
    ECR_REPO=$(terraform output -raw ecr_repository_url)
    AWS_REGION=$(terraform output -raw aws_region)

    # Login to ECR
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO

    # Build and push image
    docker build -t $ECR_REPO:v1.0.0 .
    docker push $ECR_REPO:v1.0.0

    # Tag as latest
    docker tag $ECR_REPO:v1.0.0 $ECR_REPO:latest
    docker push $ECR_REPO:latest
    ```

    ### Step 2: Run Database Migrations

    ```bash
    # Create a one-time task for migrations
    aws ecs run-task \
        --cluster $(terraform output -raw ecs_cluster_name) \
        --task-definition $(terraform output -raw blue_task_definition_arn) \
        --overrides '{
            "containerOverrides": [
                {
                    "name": "django-app",
                    "command": ["python", "manage.py", "migrate", "--settings=myproject.settings.production"]
                }
            ]
        }' \
        --launch-type EC2
    ```

    ### Step 3: Create Superuser (Optional)

    ```bash
    # Create superuser
    aws ecs run-task \
        --cluster $(terraform output -raw ecs_cluster_name) \
        --task-definition $(terraform output -raw blue_task_definition_arn) \
        --overrides '{
            "containerOverrides": [
                {
                    "name": "django-app",
                    "command": ["python", "manage.py", "createsuperuser", "--noinput", "--username=admin", "--email=admin@example.com", "--settings=myproject.settings.production"],
                    "environment": [
                        {
                            "name": "DJANGO_SUPERUSER_PASSWORD",
                            "value": "your-admin-password"
                        }
                    ]
                }
            ]
        }' \
        --launch-type EC2
    ```

    ### Step 4: Update ECS Service

    ```bash
    # Update the blue service to start serving traffic
    aws ecs update-service \
        --cluster $(terraform output -raw ecs_cluster_name) \
        --service $(terraform output -raw blue_service_name) \
        --desired-count 2
    ```

    ### Step 5: Verify Deployment

    ```bash
    # Check service status
    ./scripts/deploy.sh status

    # Test application
    curl -k https://$(terraform output -raw application_url)/health/

    # Check logs
    aws logs tail /ecs/django-app --follow
    ```

    </details>

---

-   <details><summary style="font-size:25px;color:Orange">Blue-Green Deployment Process</summary>

    ### Automated Deployment

    The deployment script automates the entire Blue-Green deployment process:

    ```bash
    # Deploy new version
    ./scripts/deploy.sh deploy v1.1.0

    # Check status
    ./scripts/deploy.sh status

    # Rollback if needed
    ./scripts/deploy.sh rollback
    ```

    ### Manual Blue-Green Deployment

    ##### Step 1: Prepare New Version

    ```bash
    # Build and push new version
    ./scripts/deploy.sh build v1.1.0 green
    ```

    ##### Step 2: Update Inactive Environment

    ```bash
    # Get current active environment
    ACTIVE_ENV=$(terraform output -raw active_environment)
    NEW_ENV=$([ "$ACTIVE_ENV" = "blue" ] && echo "green" || echo "blue")

    echo "Current active: $ACTIVE_ENV"
    echo "Deploying to: $NEW_ENV"

    # Update task definition with new image
    # This is handled by Terraform when you update app_versions
    terraform apply -var="app_versions={\"blue\"=\"v1.0.0\",\"green\"=\"v1.1.0\"}"
    ```

    ##### Step 3: Scale Up New Environment

    ```bash
    # Scale up new environment
    aws ecs update-service \
        --cluster $(terraform output -raw ecs_cluster_name) \
        --service $(terraform output -raw "${NEW_ENV}_service_name") \
        --desired-count 2
    ```

    ##### Step 4: Wait for Health Checks

    ```bash
    # Wait for service to stabilize
    aws ecs wait services-stable \
        --cluster $(terraform output -raw ecs_cluster_name) \
        --services $(terraform output -raw "${NEW_ENV}_service_name")

    # Check target group health
    TG_ARN=$(terraform output -raw "${NEW_ENV}_target_group_arn")
    aws elbv2 describe-target-health --target-group-arn $TG_ARN
    ```

    ##### Step 5: Test New Environment

    ```bash
    # Test new environment
    TEST_URL=$(terraform output -raw "${NEW_ENV}_test_url")
    curl -k $TEST_URL/health/

    # Run additional tests
    curl -k $TEST_URL/admin/
    ```

    ##### Step 6: Switch Traffic

    ```bash
    # Switch traffic to new environment
    LISTENER_ARN=$(terraform output -raw listener_arn)
    NEW_TG_ARN=$(terraform output -raw "${NEW_ENV}_target_group_arn")

    aws elbv2 modify-listener \
        --listener-arn $LISTENER_ARN \
        --default-actions Type=forward,TargetGroupArn=$NEW_TG_ARN
    ```

    ##### Step 7: Monitor and Verify

    ```bash
    # Monitor application
    PROD_URL=$(terraform output -raw application_url)
    for i in {1..10}; do
        curl -k $PROD_URL/health/
        sleep 5
    done
    ```

    ##### Step 8: Scale Down Old Environment

    ```bash
    # Scale down old environment
    aws ecs update-service \
        --cluster $(terraform output -raw ecs_cluster_name) \
        --service $(terraform output -raw "${ACTIVE_ENV}_service_name") \
        --desired-count 0

    # Update Terraform state
    terraform apply -var="active_environment=$NEW_ENV"
    ```

    ### Rollback Process

    ```bash
    # Automated rollback
    ./scripts/deploy.sh rollback

    # Manual rollback
    # 1. Scale up previous environment
    # 2. Switch traffic back
    # 3. Scale down current environment
    ```

    </details>

---

-   <details><summary style="font-size:25px;color:Orange">Monitoring and Troubleshooting</summary>

    ### CloudWatch Dashboard

    Access the dashboard:

    ```bash
    # Get dashboard URL
    terraform output cloudwatch_dashboard_url
    ```

    ### Key Metrics to Monitor

    1. **Application Load Balancer**

        - Request count
        - Response time
        - HTTP status codes
        - Target health

    2. **ECS Services**

        - CPU utilization
        - Memory utilization
        - Task count
        - Service events

    3. **RDS Database**

        - CPU utilization
        - Database connections
        - Read/Write IOPS
        - Free storage space

    4. **ElastiCache Redis**
        - CPU utilization
        - Memory usage
        - Cache hit ratio
        - Network bytes in/out

    ### Log Analysis

    ```bash
    # View ECS logs
    aws logs tail /ecs/django-app --follow

    # View specific task logs
    aws logs get-log-events \
        --log-group-name /ecs/django-app \
        --log-stream-name blue/django-app/task-id

    # Search for errors
    aws logs filter-log-events \
        --log-group-name /ecs/django-app \
        --filter-pattern "ERROR"
    ```

    ### Common Issues and Solutions

    ##### 1. Service Not Starting

    **Symptoms:**

    -   Tasks keep stopping and restarting
    -   Health checks failing

    **Solutions:**

    ```bash
    # Check task definition
    aws ecs describe-task-definition --task-definition django-app-blue

    # Check service events
    aws ecs describe-services \
        --cluster $(terraform output -raw ecs_cluster_name) \
        --services $(terraform output -raw blue_service_name)

    # Check container logs
    aws logs tail /ecs/django-app --follow
    ```

    ##### 2. Database Connection Issues

    **Symptoms:**

    -   Health checks failing with database errors
    -   Application errors in logs

    **Solutions:**

    ```bash
    # Check RDS status
    aws rds describe-db-instances

    # Verify security groups
    aws ec2 describe-security-groups --group-ids $(terraform output -raw rds_security_group_id)

    # Test database connectivity from ECS task
    aws ecs run-task \
        --cluster $(terraform output -raw ecs_cluster_name) \
        --task-definition $(terraform output -raw blue_task_definition_arn) \
        --overrides '{
            "containerOverrides": [
                {
                    "name": "django-app",
                    "command": ["python", "manage.py", "dbshell", "--settings=myproject.settings.production"]
                }
            ]
        }'
    ```

    ##### 3. Load Balancer Issues

    **Symptoms:**

    -   502/503 errors
    -   Targets showing as unhealthy

    **Solutions:**

    ```bash
    # Check target group health
    aws elbv2 describe-target-health \
        --target-group-arn $(terraform output -raw blue_target_group_arn)

    # Check ALB logs (if enabled)
    aws s3 ls s3://your-alb-logs-bucket/

    # Verify security groups
    aws ec2 describe-security-groups --group-ids $(terraform output -raw alb_security_group_id)
    ```

    </details>

---

-   <details><summary style="font-size:25px;color:Orange">Security Best Practices</summary>

    ### Network Security

    1. **VPC Configuration**

        - Use private subnets for ECS tasks
        - Implement proper security groups
        - Use NAT Gateway for outbound internet access

    2. **Security Groups**
        ```bash
        # ALB security group - only HTTP/HTTPS from internet
        # ECS security group - only from ALB
        # RDS security group - only from ECS
        ```

    ### Data Protection

    1. **Encryption at Rest**

        - RDS encryption enabled
        - S3 bucket encryption
        - EBS volume encryption

    2. **Encryption in Transit**

        - HTTPS/TLS for all communications
        - SSL for database connections
        - TLS for Redis connections

    3. **Secrets Management**

        ```bash
        # Rotate secrets regularly
        aws secretsmanager rotate-secret \
            --secret-id $(terraform output -raw db_secret_arn)

        # Update Django secret key
        aws secretsmanager update-secret \
            --secret-id $(terraform output -raw django_secret_key_arn) \
            --secret-string "new-secret-key"
        ```

    ### Access Control

    1. **IAM Roles and Policies**

        - Principle of least privilege
        - Separate roles for different components
        - Regular access reviews

    2. **Container Security**

        ```dockerfile
        # Use non-root user
        RUN adduser --disabled-password --gecos '' appuser
        USER appuser

        # Scan images for vulnerabilities
        # Use minimal base images
        ```

    ### Compliance and Auditing

    1. **CloudTrail Logging**

        - Enable API call logging
        - Monitor for suspicious activities

    2. **VPC Flow Logs**

        - Monitor network traffic
        - Detect anomalies

    </details>

---

-   <details><summary style="font-size:25px;color:Orange">Cost Optimization</summary>

    ### Right-Sizing Resources

    1. **ECS Instances**

        ```bash
        # Monitor CPU/Memory utilization
        aws cloudwatch get-metric-statistics \
            --namespace AWS/ECS \
            --metric-name CPUUtilization \
            --dimensions Name=ServiceName,Value=django-app-blue \
            --start-time 2023-01-01T00:00:00Z \
            --end-time 2023-01-02T00:00:00Z \
            --period 3600 \
            --statistics Average
        ```

    2. **RDS Instance**

        - Use appropriate instance class
        - Enable storage autoscaling
        - Consider Reserved Instances

    3. **ElastiCache**
        - Monitor memory usage
        - Use appropriate node types

    ### Auto Scaling

    1. **ECS Service Auto Scaling**

        ```bash
        # Create auto scaling target
        aws application-autoscaling register-scalable-target \
            --service-namespace ecs \
            --resource-id service/$(terraform output -raw ecs_cluster_name)/$(terraform output -raw blue_service_name) \
            --scalable-dimension ecs:service:DesiredCount \
            --min-capacity 1 \
            --max-capacity 10

        # Create scaling policy
        aws application-autoscaling put-scaling-policy \
            --service-namespace ecs \
            --resource-id service/$(terraform output -raw ecs_cluster_name)/$(terraform output -raw blue_service_name) \
            --scalable-dimension ecs:service:DesiredCount \
            --policy-name cpu-scaling \
            --policy-type TargetTrackingScaling \
            --target-tracking-scaling-policy-configuration '{
                "TargetValue": 70.0,
                "PredefinedMetricSpecification": {
                    "PredefinedMetricType": "ECSServiceAverageCPUUtilization"
                }
            }'
        ```

    2. **EC2 Auto Scaling**
        - Scale based on ECS cluster utilization
        - Use Spot Instances for cost savings

    ### Cost Monitoring

    ```bash
    # Set up billing alerts
    aws budgets create-budget \
        --account-id $(aws sts get-caller-identity --query Account --output text) \
        --budget '{
            "BudgetName": "Django-ECS-Monthly",
            "BudgetLimit": {
                "Amount": "100",
                "Unit": "USD"
            },
            "TimeUnit": "MONTHLY",
            "BudgetType": "COST"
        }'
    ```

    </details>

---

-   <details><summary style="font-size:25px;color:Orange">Advanced Scenarios</summary>

    ### Multi-Environment Setup

    ```bash
    # Create separate environments
    terraform workspace new staging
    terraform workspace new production

    # Deploy to staging
    terraform workspace select staging
    terraform apply -var-file="staging.tfvars"

    # Deploy to production
    terraform workspace select production
    terraform apply -var-file="production.tfvars"
    ```

    ### CI/CD Integration

    ##### GitHub Actions Example

    ```yaml
    # .github/workflows/deploy.yml
    name: Deploy to ECS

    on:
        push:
            branches: [main]

    jobs:
        deploy:
            runs-on: ubuntu-latest
            steps:
                - uses: actions/checkout@v2

                - name: Configure AWS credentials
                uses: aws-actions/configure-aws-credentials@v1
                with:
                    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
                    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
                    aws-region: us-east-1

                - name: Build and deploy
                run: |
                    VERSION=$(git rev-parse --short HEAD)
                    ./scripts/deploy.sh deploy $VERSION
    ```

    ### Database Migrations in Blue-Green

    ```bash
    # For backward-compatible migrations
    ./scripts/deploy.sh deploy v1.1.0

    # For breaking changes
    # 1. Deploy migration-only version
    # 2. Run migrations
    # 3. Deploy application changes
    ```

    ### Disaster Recovery

    1. **Cross-Region Backup**

        ```bash
        # Enable cross-region RDS snapshots
        aws rds modify-db-instance \
            --db-instance-identifier $(terraform output -raw db_instance_id) \
            --backup-retention-period 7
        ```

    2. **Multi-AZ Deployment**

        ```hcl
        # In terraform configuration
        resource "aws_db_instance" "django_db" {
        multi_az = true
        # ... other configuration
        }
        ```

    </details>

---

-   <details><summary style="font-size:25px;color:Orange">Conclusion</summary>

    This Django ECS deployment solution provides:

    -   **Production-ready infrastructure** with security best practices
    -   **Zero-downtime deployments** with Blue-Green strategy
    -   **Comprehensive monitoring** and alerting
    -   **Cost optimization** features
    -   **Scalability** for growing applications
    -   **Security** with encryption and proper access controls

    The combination of Terraform infrastructure-as-code and automated deployment scripts ensures consistent, reliable deployments while maintaining the flexibility to handle various deployment scenarios.

    For additional support or questions, refer to the troubleshooting section or consult the AWS documentation for specific services.

    </details>
