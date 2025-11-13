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

# resource "aws_ecs_cluster_capacity_providers" "django_cluster" {
#   cluster_name = aws_ecs_cluster.django_cluster.name

#   capacity_providers = ["EC2"]

#   default_capacity_provider_strategy {
#     base              = 1
#     weight            = 100
#     capacity_provider = "EC2"
#   }
# }

# ------------------------
# ECS Task Definition
# ------------------------
resource "aws_ecs_task_definition" "django_app" {
  for_each = toset(local.environments)

  family                   = "${var.project_name}-task_def-${each.key}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "${var.project_name}-container-def-${each.key}"
      image = "${aws_ecr_repository.django_bookstore_app.repository_url}:${var.app_versions[each.key]}"
      #   image = "${var.dockerhub_image_name}:${var.app_versions[each.key]}"

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
          name  = "DJANGO_ALLOWED_HOSTS"
          value = "${aws_lb.main.dns_name},127.0.0.1,localhost"
        },
        {
          name  = "DJANGO_CORS_ALLOWED_ORIGINS"
          value = "https://${aws_lb.main.dns_name}" # Use HTTPS if ALB uses a listener with a certificate
        },
        {
          name  = "DJANGO_STATIC_ROOT"
          value = var.django_static_root
        },
        {
          name  = "DJANGO_SETTINGS_MODULE"
          value = var.django_settings_module
        },
        # {
        #   name  = "DJANGO_DEBUG"
        #   value = tostring(var.django_debug)
        # },

      ]

      secrets = [
        {
          name      = "DJANGO_SECRET_KEY"
          valueFrom = aws_secretsmanager_secret.django_secret_key.arn
        },
        {
          name      = "DJANGO_STRIPE_SECRET_KEY"
          valueFrom = aws_secretsmanager_secret.django_stripe_secret_key.arn
        },
        {
          name      = "DJANGO_STRIPE_ENDPOINT_SECRET"
          valueFrom = aws_secretsmanager_secret.django_stripe_endpoint_secret.arn
        },
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

# ---------------------------
# ECS Services (Blue/Green)
# ---------------------------
resource "aws_ecs_service" "django_app" {
  for_each = toset(local.environments)

  name            = "${var.project_name}-service-${each.key}"
  cluster         = aws_ecs_cluster.django_cluster.id
  task_definition = aws_ecs_task_definition.django_app[each.key].arn
  desired_count   = each.key == var.active_environment ? var.service_desired_count : 0

  launch_type = "EC2" # Options: EC2, FARGATE

  network_configuration {
    subnets          = [for k, v in var.private_subnets : v.id if strcontains(k, "private")]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.environments[each.key].arn
    container_name   = "${var.project_name}-container-def-${each.key}"
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

# ---------------------------
# Auto Scaling Group for ECS
# ---------------------------
resource "aws_launch_template" "ecs_instances" {
  name_prefix   = "${var.project_name}-ecs-"
  image_id      = var.ecs_ami_id
  instance_type = var.ecs_instance_type
  key_name      = var.key_pair_name

  vpc_security_group_ids = [aws_security_group.ecs_sg.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/scripts/user_data.sh", {
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
  name                = "${var.project_name}-ecs-asg"
  vpc_zone_identifier = [for k, v in var.private_subnets : v.id if strcontains(k, "private")]
  #   target_group_arns         = values(aws_lb_target_group.environments)[*].arn
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
resource "aws_ecr_repository" "django_bookstore_app" {
  name                 = "${var.project_name}-ecr-repo"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = local.common_tags
}

resource "aws_ecr_lifecycle_policy" "django_bookstore_app" {
  repository = aws_ecr_repository.django_bookstore_app.name

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

