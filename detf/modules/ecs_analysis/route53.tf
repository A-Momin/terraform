# ACM Certificate (DNS validation)
resource "aws_acm_certificate" "cert" {
  domain_name               = var.r53_hosted_zone.name
  validation_method         = "DNS" # Options: EMAIL, DNS
  subject_alternative_names = var.subject_alternative_names

  tags = { Project = "${var.project_name}" }
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
# Route53 Records
# ------------------------
resource "aws_route53_record" "main" {
  zone_id = var.r53_hosted_zone.id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www" {
  zone_id = var.r53_hosted_zone.id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# Test subdomains for blue/green environments
resource "aws_route53_record" "blue" {
  zone_id = var.r53_hosted_zone.id
  name    = "blue.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "green" {
  zone_id = var.r53_hosted_zone.id
  name    = "green.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}
