resource "aws_security_group" "all_in_one_access_sg" {
  name        = "all-in-one-access-sg"
  description = "Security group for all-in-one access"
  vpc_id      = aws_vpc.detf_vpc.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true # 👈 Self-reference here
    description = "Allow all TCP traffic from within the same SG"
  }

  dynamic "ingress" {
    for_each = toset([22, 80])
    content {
      from_port   = ingress.key
      to_port     = ingress.key
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  dynamic "ingress" {
    for_each = toset([443, 8000, 8010, 8080])
    content {
      from_port   = ingress.key
      to_port     = ingress.key
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
