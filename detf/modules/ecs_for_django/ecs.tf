# ------------------------
# ECS Cluster
# ------------------------
resource "aws_ecs_cluster" "django_cluster" {
  name = "${var.project_name}-cluster"

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.ecs_exec.name
      }
    }
  }

  tags = local.common_tags
}

resource "aws_ecs_cluster_capacity_providers" "django_cluster" {
  cluster_name = aws_ecs_cluster.django_cluster.name

  capacity_providers = ["EC2"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "EC2"
  }
}

# ------------------------
# ECS Task Definition
# ------------------------

# Local values
locals {
  environments = ["blue", "green"]

  common_tags = {
    Project     = var.project_name
    Environment = "ecs-django"
    ManagedBy   = "terraform"
  }
}

resource "aws_ecs_task_definition" "django_app" {
  for_each = toset(local.environments)

  family                   = "${var.project_name}-${each.key}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "django-app"
      image = "${aws_ecr_repository.django_app.repository_url}:${var.app_versions[each.key]}"

      portMappings = [
        {
          containerPort = 8000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "ENVIRONMENT"
          value = each.key
        },
        {
          name  = "DEBUG"
          value = "False"
        },
        {
          name  = "ALLOWED_HOSTS"
          value = var.domain_name
        },
        {
          name  = "STATIC_URL"
          value = "https://${aws_cloudfront_distribution.static.domain_name}/static/"
        },
        {
          name  = "MEDIA_URL"
          value = "https://${aws_cloudfront_distribution.media.domain_name}/media/"
        },
        {
          name  = "AWS_STORAGE_BUCKET_NAME_STATIC"
          value = aws_s3_bucket.django_static.bucket
        },
        {
          name  = "AWS_STORAGE_BUCKET_NAME_MEDIA"
          value = aws_s3_bucket.django_media.bucket
        },
        {
          name  = "REDIS_URL"
          value = "redis://${aws_elasticache_replication_group.django_cache.primary_endpoint_address}:6379"
        }
      ]

      secrets = [
        {
          name      = "SECRET_KEY"
          valueFrom = aws_secretsmanager_secret.django_secret_key.arn
        },
        {
          name      = "DATABASE_URL"
          valueFrom = "${aws_secretsmanager_secret.db_credentials.arn}:host::"
        },
        {
          name      = "DB_NAME"
          valueFrom = "${aws_secretsmanager_secret.db_credentials.arn}:dbname::"
        },
        {
          name      = "DB_USER"
          valueFrom = "${aws_secretsmanager_secret.db_credentials.arn}:username::"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.db_credentials.arn}:password::"
        },
        {
          name      = "DB_HOST"
          valueFrom = "${aws_secretsmanager_secret.db_credentials.arn}:host::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.django_app.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = each.key
        }
      }

      healthCheck = {
        command = [
          "CMD-SHELL",
          "curl -f http://localhost:8000/health/ || exit 1"
        ]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      essential = true
    }
  ])

  tags = merge(local.common_tags, {
    Environment = each.key
  })
}

# ------------------------
# ECS Services (Blue/Green)
# ------------------------
resource "aws_ecs_service" "django_app" {
  for_each = toset(local.environments)

  name            = "${var.project_name}-${each.key}"
  cluster         = aws_ecs_cluster.django_cluster.id
  task_definition = aws_ecs_task_definition.django_app[each.key].arn
  desired_count   = each.key == var.active_environment ? var.service_desired_count : 0

  launch_type = "EC2" # Options: EC2, FARGATE

  network_configuration {
    subnets          = data.aws_subnets.private.ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.environments[each.key].arn
    container_name   = "django-app"
    container_port   = 8000
  }

  depends_on = [aws_lb_listener.https]

  tags = merge(local.common_tags, {
    Environment = each.key
  })

  lifecycle {
    ignore_changes = [desired_count]
  }
}


# ------------------------
# Auto Scaling Group for ECS
# ------------------------
resource "aws_launch_template" "ecs_instances" {
  name_prefix   = "${var.project_name}-ecs-"
  image_id      = var.ecs_ami_id
  instance_type = var.ecs_instance_type
  key_name      = var.key_pair_name

  vpc_security_group_ids = [aws_security_group.ecs_sg.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    cluster_name = aws_ecs_cluster.django_cluster.name
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "${var.project_name}-ecs-instance"
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ecs_asg" {
  name                      = "${var.project_name}-ecs-asg"
  vpc_zone_identifier       = data.aws_subnets.private.ids
  target_group_arns         = values(aws_lb_target_group.environments)[*].arn
  health_check_type         = "ELB"
  health_check_grace_period = 300

  min_size         = var.asg_config.min_size
  max_size         = var.asg_config.max_size
  desired_capacity = var.asg_config.desired_capacity

  launch_template {
    id      = aws_launch_template.ecs_instances.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-ecs-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}


# ------------------------
# ECR Repository
# ------------------------
resource "aws_ecr_repository" "django_app" {
  name                 = "${var.project_name}-django"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = local.common_tags
}

resource "aws_ecr_lifecycle_policy" "django_app" {
  repository = aws_ecr_repository.django_app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ------------------------
# CloudWatch Log Groups
# ------------------------
resource "aws_cloudwatch_log_group" "django_app" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "ecs_exec" {
  name              = "/aws/ecs/exec/${var.project_name}"
  retention_in_days = 7

  tags = local.common_tags
}


# ------------------------
# ECS Instance Profile
# ------------------------
resource "aws_iam_role" "ecs_instance_role" {
  name = "${var.project_name}-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${var.project_name}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name

  tags = local.common_tags
}
