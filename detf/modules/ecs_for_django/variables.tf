# Variables for Django ECS Deployment

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "bookstore"
}

variable "existing_vpc_id" {
  description = "ID of the existing VPC"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "harnesstech.com"
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate"
  type        = string
}

variable "key_pair_name" {
  description = "Name of the EC2 key pair"
  type        = string
}

# Database Configuration
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "djangodb"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "djangouser"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

# ECS Configuration
variable "ecs_ami_id" {
  description = "AMI ID for ECS instances"
  type        = string
  default     = "ami-0c02fb55956c7d316" # ECS-optimized Amazon Linux 2
}

variable "ecs_instance_type" {
  description = "EC2 instance type for ECS"
  type        = string
  default     = "t3.small"
}

variable "task_cpu" {
  description = "CPU units for the task"
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Memory for the task"
  type        = number
  default     = 1024
}

variable "service_desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 2
}

variable "active_environment" {
  description = "Currently active environment (blue or green)"
  type        = string
  default     = "blue"

  validation {
    condition     = contains(["blue", "green"], var.active_environment)
    error_message = "Active environment must be either 'blue' or 'green'."
  }
}

variable "app_versions" {
  description = "Application versions for blue and green environments"
  type        = map(string)
  default = {
    blue  = "latest"
    green = "latest"
  }
}

variable "asg_config" {
  description = "Auto Scaling Group configuration"
  type = object({
    min_size         = number
    max_size         = number
    desired_capacity = number
  })
  default = {
    min_size         = 2
    max_size         = 6
    desired_capacity = 2
  }
}

# Environment Variables for Django
variable "django_settings_module" {
  description = "Django settings module"
  type        = string
  default     = "myproject.settings.production"
}

variable "django_debug" {
  description = "Django debug mode"
  type        = bool
  default     = false
}
