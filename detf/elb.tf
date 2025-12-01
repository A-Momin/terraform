# ------------------------
# Application Load Balancer
# ------------------------
resource "aws_lb" "main" {
  name               = "${var.project}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [for k, v in aws_subnet.public_subnets : v.id]

  enable_deletion_protection = false

}

# ------------------------
# Target Groups (Blue and Green)
# ------------------------
# resource "aws_lb_target_group" "environments" {
#   for_each = toset(local.environments)

#   name        = "${var.project}-${each.key}-tg"
#   target_type = "instance" # Options: "ip", "instance", "lambda"; default is "instance"
#   port        = 80
#   protocol    = "HTTP"
#   vpc_id      = var.vpc_id

#   #   health_check {
#   #     enabled             = true
#   #     healthy_threshold   = 2
#   #     unhealthy_threshold = 2
#   #     timeout             = 5
#   #     interval            = 30
#   #     path                = "/health/"
#   #     matcher             = "200"
#   #     port                = "traffic-port"
#   #     protocol            = "HTTP"
#   #   }

#   tags = merge(local.common_tags, {
#     Name        = "${var.project}-${each.key}-tg"
#     Environment = each.key
#   })

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# ------------------------
# ALB Listeners
# ------------------------
# resource "aws_lb_listener" "http" {
#   load_balancer_arn = aws_lb.main.arn
#   port              = "80"
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     # # This config integrates `aws_lb` (through it's listener) with `aws_lb_target_group`
#     target_group_arn = aws_lb_target_group.environments[var.active_environment].arn
#   }
#     # default_action {
#     #   type = "redirect"

#     #   redirect {
#     #     port        = "443"
#     #     protocol    = "HTTPS"
#     #     status_code = "HTTP_301"
#     #   }
#     # }

#   tags = local.common_tags
# }


# ------------------------
# ALB Listener Rules for Testing
# ------------------------
# resource "aws_lb_listener_rule" "blue_test" {
#     listener_arn = aws_lb_listener.http.arn
#   priority     = 100

#   action {
#     type             = "forward"
#     # # This config integrates `aws_lb` (through it's listener) with `aws_lb_target_group`
#     target_group_arn = aws_lb_target_group.environments["blue"].arn
#   }

#   condition {
#     host_header {
#       values = ["blue.${var.domain_name}"]
#     }
#   }

#   tags = merge(local.common_tags, { Environment = "blue" })
# }

# resource "aws_lb_listener_rule" "green_test" {
#     listener_arn = aws_lb_listener.http.arn
#   priority     = 101

#   action {
#     type             = "forward"
#     # # This config integrates `aws_lb` (through it's listener) with `aws_lb_target_group`
#     target_group_arn = aws_lb_target_group.environments["green"].arn
#   }

#   condition {
#     host_header {
#       values = ["green.${var.domain_name}"]
#     }
#   }

#   tags = merge(local.common_tags, { Environment = "green" })
# }


resource "aws_security_group" "alb_sg" {
  name_prefix = "${var.project}-alb-"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.detf_vpc.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

#   tags = merge(local.common_tags, { Name = "${var.project}-alb-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "ecs_container_instance_sg" {
  name_prefix = "${var.project}-ecs-"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.detf_vpc.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description     = "HTTP from ALB"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks = var.VPC_CIDR != null ? [var.VPC_CIDR] : []
  }

  ingress {
    description     = "Allow Django App Port from the same VPC"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    cidr_blocks = var.VPC_CIDR != null ? [var.VPC_CIDR] : []
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

#   tags = merge(local.common_tags, {Name = "${var.project}-ecs-sg"})

  lifecycle {
    create_before_destroy = true
  }
}


