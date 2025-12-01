# -------------------------
# Security Group for EC2
# -------------------------
resource "aws_security_group" "ec2_dev_sg" {
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

  dynamic "ingress" {
    for_each = toset([443, 8000, 8010])
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

# -------------------------
# Launch Template
# -------------------------
resource "aws_launch_template" "ec2_dev_lt" {
  name_prefix            = "${var.project}-lt"
  image_id               = data.aws_ami.amazon_lnx_2023.id
  instance_type          = "t3.medium" # Options: t3.micro, t3.small, t3.medium
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.ec2_dev_sg.id]


  #   iam_instance_profile {
  #     name = aws_iam_instance_profile.ec2_profile.name
  #   }

  user_data = base64encode(
    var.script_type == "ubuntu" ?
    file("${path.module}/ubuntu_lnx_setup.sh") :
    file("${path.module}/amazon_lnx_setup.sh")
  )

  # --- START: VOLUME SIZE ADDITION ---
  block_device_mappings {
    device_name = "/dev/xvda" # Common root device name for Linux AMIs

    ebs {
      # Sets the root volume size to 20 GB
      volume_size = 20

      # Optional: Better performance than default magnetic, standard for SSDs
      volume_type = "gp3"

      # Ensure it is deleted when the instance is terminated
      delete_on_termination = true
    }
  }
}

# -------------------------
# Launch EC2 Instance from LT
# -------------------------
resource "aws_instance" "ec2_dev_environment" {
  subnet_id                   = var.subnet_id
  key_name                    = var.key_name
  user_data_replace_on_change = true # Replace the user data when it changes
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name


  # Use the launch_template block to reference your defined template
  launch_template {
    # Reference the ID of your launch template resource
    id = aws_launch_template.ec2_dev_lt.id

    # Use the default version ($Latest or $Default are common, but using $Latest is usually preferred)
    version = "$Latest"
    # version = "$Default"
  }

  # Optional: Add tags for identification and organization
  tags = {
    Name        = "${var.project}-instance"
    Environment = "Development"
  }
}

# data "aws_ami" "latest_ubuntu_2404" {
#   most_recent = true
#   owners      = ["099720109477"] # Canonical ID

#   filter {
#     name = "name"
#     # Use a broader pattern. This targets any official 24.04 server image.
#     values = ["*ubuntu-noble-24.04-amd64-server-*"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }

#   filter {
#     name   = "state"
#     values = ["available"]
#   }
# }

# Data block to dynamically retrieve the latest Amazon Linux 2023 AMI ID
data "aws_ami" "amazon_lnx_2023" {
  # We look for AMIs owned by Amazon
  owners = ["amazon"]

  # Filter for the latest Amazon Linux 2023 AMI (minimal version)
  filter {
    name   = "name"
    values = ["al2023-ami-minimal-*-kernel-*"]
  }

  # Ensure the image is ready for use
  filter {
    name   = "state"
    values = ["available"]
  }

  # Get the most recent image
  most_recent = true
}

resource "aws_eip" "ec2_dev_eip" {
  #   vpc = true
  domain = "vpc"
  tags = {
    Name = "${var.project}-eip"
  }
}

resource "aws_eip_association" "ec2_dev_eip_assoc" {
  instance_id   = aws_instance.ec2_dev_environment.id
  allocation_id = aws_eip.ec2_dev_eip.id
}

resource "null_resource" "ec2_dev_bash_config" {

  depends_on = [aws_instance.ec2_dev_environment]

  provisioner "local-exec" {
    command = <<-EOT
        scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/${var.key_name}.pem ${var.bash_config_scripts_location}/.bashrc ${var.ec2_username}@${aws_eip.ec2_dev_eip.public_ip}:/home/${var.ec2_username}/.bashrc
        scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/${var.key_name}.pem ${var.bash_config_scripts_location}/.bash_profile ${var.ec2_username}@${aws_eip.ec2_dev_eip.public_ip}:/home/${var.ec2_username}/.bash_profile
        scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/${var.key_name}.pem ${var.bash_config_scripts_location}/.aliases ${var.ec2_username}@${aws_eip.ec2_dev_eip.public_ip}:/home/${var.ec2_username}/.aliases
        scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/${var.key_name}.pem ${var.bash_config_scripts_location}/.git-aliases.bash ${var.ec2_username}@${aws_eip.ec2_dev_eip.public_ip}:/home/${var.ec2_username}/.git-aliases.bash
        scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/${var.key_name}.pem ${var.bash_config_scripts_location}/.git-completion.bash ${var.ec2_username}@${aws_eip.ec2_dev_eip.public_ip}:/home/${var.ec2_username}/.git-completion.bash
        scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/${var.key_name}.pem ${var.bash_config_scripts_location}/.git-prompt.sh ${var.ec2_username}@${aws_eip.ec2_dev_eip.public_ip}:/home/${var.ec2_username}/.git-prompt.sh
        # scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/${var.key_name}.pem ${var.bash_config_scripts_location}/.vimrc ${var.ec2_username}@${aws_eip.ec2_dev_eip.public_ip}:/home/${var.ec2_username}/.vimrc
        scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/${var.key_name}.pem ${var.bash_config_scripts_location}/.bash_utils.sh ${var.ec2_username}@${aws_eip.ec2_dev_eip.public_ip}:/home/${var.ec2_username}/.bash_utils.sh
        scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/${var.key_name}.pem ${var.bash_config_scripts_location}/.secrets.bash ${var.ec2_username}@${aws_eip.ec2_dev_eip.public_ip}:/home/${var.ec2_username}/.secrets.bash
        scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/${var.key_name}.pem ${var.bash_config_scripts_location}/automate_installations.sh ${var.ec2_username}@${aws_eip.ec2_dev_eip.public_ip}:/home/${var.ec2_username}/.automate_installations.sh
    EOT
  }
}
