# ------------------------
# Application Load Balancer
# ------------------------
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.public.ids

  enable_deletion_protection = false

  tags = local.common_tags
}

# ------------------------
# Target Groups (Blue and Green)
# ------------------------
resource "aws_lb_target_group" "environments" {
  for_each = toset(local.environments)

  name     = "${var.project_name}-${each.key}-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.existing.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health/"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = merge(local.common_tags, {
    Name        = "${var.project_name}-${each.key}-tg"
    Environment = each.key
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ------------------------
# ALB Listeners
# ------------------------
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = local.common_tags
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"
  certificate_arn   = var.certificate_arn

  # Default action points to the active environment
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.environments[var.active_environment].arn
  }

  tags = local.common_tags
}


# ------------------------
# ALB Listener Rules for Testing
# ------------------------
resource "aws_lb_listener_rule" "blue_test" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.environments["blue"].arn
  }

  condition {
    host_header {
      values = ["blue.${var.domain_name}"]
    }
  }

  tags = merge(local.common_tags, {
    Environment = "blue"
  })
}

resource "aws_lb_listener_rule" "green_test" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.environments["green"].arn
  }

  condition {
    host_header {
      values = ["green.${var.domain_name}"]
    }
  }

  tags = merge(local.common_tags, {
    Environment = "green"
  })
}
