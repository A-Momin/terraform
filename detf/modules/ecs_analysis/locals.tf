
# Local values
locals {
  environments = ["blue", "green"]

  common_tags = {
    Project     = var.project_name
    Environment = "ecs-django"
    ManagedBy   = "terraform"
  }

}

