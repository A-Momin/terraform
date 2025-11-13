variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "bookstore"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc" {
  description = "The VPC object"
  type        = any
}

variable "public_subnets" {
  description = "Map of public subnet IDs"
  type = map(object({
    id                = string
    availability_zone = string
  }))
  #   type        = map(any)
}

variable "private_subnets" {
  description = "Map of private subnet IDs"
  type        = map(any)

  #   # If you only need a few fields (e.g., `id` and `availability_zone`), you can define a smaller object:
  #   type = map(object({
  #     id                = string
  #     availability_zone = string
  #   }))
}

# ================================================================
# Route53 Configuration Variables
# ================================================================
variable "r53_hosted_zone" {
  description = "The domain name of the Route53 hosted zone"
  type        = any
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "harnesstech.com"
}

variable "subject_alternative_names" {
  description = "List of Subject Alternative Names (SANs) for the ACM certificate"
  type        = list(string)
  default     = ["www.harnesstechtx.com", "blue.harnesstechtx.com", "green.harnesstechtx.com"]
}

# variable "existing_vpc_id" {
#   description = "ID of the existing VPC"
#   type        = string
# }

# variable "certificate_arn" {
#   description = "ARN of the SSL certificate"
#   type        = string
# }


# ================================================================
# ECS Configuration Variables
# ================================================================
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

variable "key_pair_name" {
  description = "Name of the EC2 key pair"
  type        = string
  default     = "general_purpose"
}

variable "dockerhub_image_name" {
  description = "The full name of the image on Docker Hub (e.g., username/repo)."
  type        = string
  default     = "bbcredcap3/harness"
}

# ================================================================
# Environment Variables for Django Application
# ================================================================
variable "django_settings_module" {
  description = "Django settings module"
  type        = string
  default     = "myproject.settings.production"
}

variable "django_static_root" {
  description = "Django settings module"
  type        = string
  default     = ""
}

variable "django_debug" {
  description = "Django debug mode"
  type        = bool
  default     = false
}

variable "django_secret_key" {
  description = ""
  type        = string
  sensitive   = true # Mark as sensitive to prevent output in logs/state
}

variable "django_stripe_secret_key" {
  description = ""
  type        = string
  sensitive   = true # Mark as sensitive to prevent output in logs/state
}

variable "django_stripe_endpoint_secret" {
  description = ""
  type        = string
  sensitive   = true # Mark as sensitive to prevent output in logs/state
}

# ================================================================
# # Database Configuration Variables
# ================================================================
# variable "db_name" {
#   description = "Database name"
#   type        = string
#   default     = "djangodb"
# }

# variable "db_username" {
#   description = "Database username"
#   type        = string
#   default     = "djangouser"
# }

# variable "db_instance_class" {
#   description = "RDS instance class"
#   type        = string
#   default     = "db.t3.micro"
# }
