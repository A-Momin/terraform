
# Django ECS Deployment with Blue-Green Support
# This configuration creates a complete ECS infrastructure for Django applications

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources for existing infrastructure
data "aws_vpc" "existing" {
  id = var.existing_vpc_id
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }

  filter {
    name   = "tag:Name"
    values = ["*public*"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }

  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

data "aws_route53_zone" "existing" {
  name = var.domain_name
}


# ------------------------
# ElastiCache Redis
# ------------------------
resource "aws_elasticache_subnet_group" "django_cache" {
  name       = "${var.project_name}-cache-subnet-group"
  subnet_ids = data.aws_subnets.private.ids

  tags = local.common_tags
}

resource "aws_security_group" "redis_sg" {
  name_prefix = "${var.project_name}-redis-"
  description = "Security group for Redis cache"
  vpc_id      = data.aws_vpc.existing.id

  ingress {
    description     = "Redis from ECS"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-redis-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elasticache_replication_group" "django_cache" {
  replication_group_id = "${var.project_name}-cache"
  description          = "Redis cache for Django application"

  node_type            = "cache.t3.micro"
  port                 = 6379
  parameter_group_name = "default.redis7"

  num_cache_clusters         = 2
  automatic_failover_enabled = true
  multi_az_enabled           = true

  subnet_group_name  = aws_elasticache_subnet_group.django_cache.name
  security_group_ids = [aws_security_group.redis_sg.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  tags = local.common_tags
}


# ------------------------
# CloudWatch Dashboard
# ------------------------
resource "aws_cloudwatch_dashboard" "django_app" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.main.arn_suffix],
            [".", "RequestCount", ".", "."],
            [".", "HTTPCode_Target_2XX_Count", ".", "."],
            [".", "HTTPCode_Target_4XX_Count", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "ALB Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", aws_ecs_service.django_app["blue"].name, "ClusterName", aws_ecs_cluster.django_cluster.name],
            [".", "MemoryUtilization", ".", ".", ".", "."],
            ["AWS/ECS", "CPUUtilization", "ServiceName", aws_ecs_service.django_app["green"].name, "ClusterName", aws_ecs_cluster.django_cluster.name],
            [".", "MemoryUtilization", ".", ".", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "ECS Service Metrics"
          period  = 300
        }
      }
    ]
  })
}
