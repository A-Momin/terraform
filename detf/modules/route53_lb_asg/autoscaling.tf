# ------------------------
# Launch Template + ASG
# ------------------------
resource "aws_launch_template" "lt" {
  name          = "${var.project}-lt"
  image_id      = "ami-053a45fff0a704a47"
  instance_type = "t2.micro"
  key_name      = "AMShah"

  tag_specifications {
    resource_type = "instance"

    tags = {
      Project = "${var.project}"
      Name    = "${var.project}-instance"
    }
  }

  user_data = base64encode(<<-EOF
        #!/bin/bash
        # Update the system and install Apache
        yum update -y
        yum install -y httpd

        # Start and enable Apache to run on boot
        systemctl start httpd
        systemctl enable httpd

        # When working with EC2 instance metadata, the token URL is fixed and standard across all EC2 instances — it always fetches the latest token for accessing EC2 instance metadata
        TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

        # Fetch the instance ID
        INSTANCEID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id -H "X-aws-ec2-metadata-token: $TOKEN")

        # Create or overwrite `index.html` with the instance ID information
        echo "<center><h1>This instance has the ID: $INSTANCEID </h1></center>" > /var/www/html/index.html

        # Ensure httpd can read the `index.html` file and its directory
        chown apache:apache /var/www/html/index.html
        chmod 755 /var/www/html
        chmod 644 /var/www/html/index.html

        # Restart Apache to apply changes
        systemctl restart httpd
        EOF
  )

  vpc_security_group_ids = [aws_security_group.web_ec2_sg.id]
}

resource "aws_autoscaling_group" "asg" {
  name                = "${var.project}-asg"
  max_size            = 4
  min_size            = 2
  desired_capacity    = 2
  vpc_zone_identifier = [for k, v in var.private_subnets : v.id if strcontains(k, "private")]
  #   vpc_zone_identifier = [for k, v in var.public_subnets : v.id if strcontains(k, "public")]

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.tg.arn]

  tag {
    key                 = "Project"
    value               = var.project
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "scale_out_in" {
  name                   = "TargetTrackingPolicy"  # Options: StepScaling, TargetTrackingScaling, SimpleScaling
  policy_type            = "TargetTrackingScaling" # Options: StepScaling, TargetTrackingScaling, SimpleScaling
  autoscaling_group_name = aws_autoscaling_group.asg.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.alb.arn_suffix}/${aws_lb_target_group.tg.arn_suffix}"
    }
    target_value = 50.0
  }
}
