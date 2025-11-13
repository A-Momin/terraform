output "dev_instance_public_ip" {
  value = aws_eip.ec2_dev_eip.public_ip # module.ec2_dev_instance.dev_instance_public_ip
}
