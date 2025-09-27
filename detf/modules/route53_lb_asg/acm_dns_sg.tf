# ACM Certificate (DNS validation)
resource "aws_acm_certificate" "cert" {
  domain_name               = var.r53_hosted_zone.name
  validation_method         = "DNS" # Options: EMAIL, DNS
  subject_alternative_names = var.subject_alternative_names

  tags = { Project = "${var.project}" }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  zone_id = var.r53_hosted_zone.id # hosted zone id
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}


# ------------------------
# Route53 ALIAS to ALB
# ------------------------
resource "aws_route53_record" "alb_alias" {
  zone_id = var.r53_hosted_zone.id
  name    = var.r53_hosted_zone.name
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www_cname" {
  zone_id = var.r53_hosted_zone.id
  name    = "www"
  type    = "CNAME"
  ttl     = 300
  records = ["harnesstechtx.com"]
}

resource "aws_route53_record" "sub_alias" {
  zone_id = var.r53_hosted_zone.id
  name    = "sub"
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}

# ------------------------
# Security Groups
# ------------------------
resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "ALB SG"
  vpc_id      = var.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
}

resource "aws_security_group" "web_ec2_sg" {
  name        = "web_ec2_sg"
  description = "Web SG"
  vpc_id      = var.vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  #   ingress {
  #     from_port   = 80
  #     to_port     = 80
  #     protocol    = "tcp"
  #     cidr_blocks = ["66.69.52.30/32"] # Replace with your IP
  #   }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
