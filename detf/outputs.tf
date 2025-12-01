output "dev_instance_public_ip" { # <--- This name must match the command
  description = "Public IP exposed from the dev EC2 sub-module."
  # Reference should be: module.<module_name>.<submodule_output_name>
  value = module.ec2_dev_environment.dev_instance_public_ip
}

output "vpc_id" {
    value = aws_vpc.detf_vpc.id
}

output "private_subnets" {
    value = [for k, v in aws_subnet.private_subnets : v.id]
}

output "public_subnets" {
    value = [for k, v in aws_subnet.public_subnets : v.id]
}
output "r53_hosted_zone_name" {
    value = aws_route53_zone.harnesstech_public_zone.name
}

output "r53_hosted_zone_id" {
    value = aws_route53_zone.harnesstech_public_zone.id
}
