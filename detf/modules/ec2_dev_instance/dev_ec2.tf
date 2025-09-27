# -------------------------
# Security Group for EC2
# -------------------------
resource "aws_security_group" "dev_ec2_sg" {
  name        = "${var.project}-sg"
  description = "Allow SSH, HTTP, Jenkins"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins"
    from_port   = 8080
    to_port     = 8080
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

# -------------------------
# Launch Template
# -------------------------
resource "aws_launch_template" "dev_ec2_lt" {
  name_prefix            = "${var.project}-lt-"
  image_id               = data.aws_ami.amazon_linux2.id
  instance_type          = "t3.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.dev_ec2_sg.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              # Update system
              yum update -y

              # Install Docker
              amazon-linux-extras enable docker
              yum install -y docker
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user

              # Install Java (required for Jenkins)
              yum install -y java-11-amazon-corretto

              # Add Jenkins repo
              wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
              rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

              # Install Jenkins
              yum install -y jenkins

              # Start Jenkins
              systemctl enable jenkins
              systemctl start jenkins
              EOF
  )
}

# -------------------------
# Launch EC2 Instance from LT
# -------------------------
resource "aws_instance" "dev_ec2_instance" {
  ami                    = data.aws_ami.amazon_linux2.id
  instance_type          = "t3.micro"
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.dev_ec2_sg.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras enable docker
              yum install -y docker
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user
              yum install -y java-11-amazon-corretto
              wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
              rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
              yum install -y jenkins
              systemctl enable jenkins
              systemctl start jenkins
              EOF
  )
}

# -------------------------
# AMI Lookup
# -------------------------
data "aws_ami" "amazon_linux2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_eip" "dev_ec2_eip" {
  #   vpc = true
  domain = "vpc"
  tags = {
    Name = "${var.project}-eip"
  }
}

resource "aws_eip_association" "dev_ec2_eip_assoc" {
  instance_id   = aws_instance.dev_ec2_instance.id
  allocation_id = aws_eip.dev_ec2_eip.id
}
