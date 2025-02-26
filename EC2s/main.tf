# Generated from ChatGPT
# YET NOT TESTED !!
# ============================================================================

provider "aws" {
  region = "us-east-1"  # Update with your desired AWS region
}

resource "aws_key_pair" "example_key" {
  key_name   = "example-key"
  public_key = file("~/.ssh/id_rsa.pub")  # Update with the path to your public key
}

resource "aws_instance" "example_instance" {
  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI (us-east-1)
  instance_type = "t2.micro"
  key_name      = aws_key_pair.example_key.key_name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              service httpd start
              chkconfig httpd on
              echo "Hello from Terraform" > /var/www/html/index.html
              EOF

  tags = {
    Name = "example-instance"
  }
}

# Provisioner to copy files from the local machine to the EC2 instance
resource "null_resource" "example_provisioner" {
  depends_on = [aws_instance.example_instance]

  provisioner "file" {
    source      = "path/to/local/directory"  # Update with the path to your local directory
    destination = "/home/ec2-user/"  # Destination directory on the EC2 instance

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")  # Update with the path to your private key
      host        = aws_instance.example_instance.public_ip
    }
  }
}
