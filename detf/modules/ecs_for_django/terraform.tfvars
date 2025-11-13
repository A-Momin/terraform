# Example terraform.tfvars file for Django ECS Deployment

# AWS Configuration
aws_region = "us-east-1"

# Project Configuration
project_name = "django-app"

# Existing Infrastructure
existing_vpc_id = "vpc-xxxxxxxxx"  # Replace with your VPC ID
certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  # Replace with your certificate ARN
domain_name     = "harnesstech.com"
key_pair_name   = "your-key-pair"  # Replace with your key pair name

# Database Configuration
db_name           = "djangodb"
db_username       = "djangouser"
db_instance_class = "db.t3.micro"

# ECS Configuration
ecs_ami_id         = "ami-0c02fb55956c7d316"  # ECS-optimized Amazon Linux 2
ecs_instance_type  = "t3.small"
task_cpu           = 512
task_memory        = 1024
service_desired_count = 2

# Blue-Green Configuration
active_environment = "blue"
app_versions = {
  blue  = "v1.0.0"
  green = "v1.1.0"
}

# Auto Scaling Configuration
asg_config = {
  min_size         = 2
  max_size         = 6
  desired_capacity = 2
}

# Django Configuration
django_settings_module = "myproject.settings.production"
django_debug          = false