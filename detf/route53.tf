resource "aws_route53_zone" "harnesstech_public_zone" {
  name          = "harnesstechtx.com"
  comment       = "Public hosted zone for harnesstechtx.com"
  force_destroy = true # Set true if you want to delete records with zone

  tags = {
    Project = "${var.project}"
  }
}

