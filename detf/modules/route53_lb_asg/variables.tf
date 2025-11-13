variable "project" {
  description = "Project name tag"
  type        = string
  default     = "route53-lb-asg"
}

variable "r53_hosted_zone" {
  description = "The domain name of the Route53 hosted zone"
  type        = any
}

variable "subject_alternative_names" {
  description = "List of Subject Alternative Names (SANs) for the ACM certificate"
  type        = list(string)
  default     = ["www.harnesstechtx.com", "sub.harnesstechtx.com"]
}

variable "vpc" {
  description = "The VPC object"
  type        = any
}

variable "public_subnets" {
  description = "Map of public subnet IDs"
  type = map(object({
    id                = string
    availability_zone = string
  }))
  #   type        = map(any)
}

variable "private_subnets" {
  description = "Map of private subnet IDs"
  type        = map(any)

  #   # If you only need a few fields (e.g., `id` and `availability_zone`), you can define a smaller object:
  #   type = map(object({
  #     id                = string
  #     availability_zone = string
  #   }))
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
  default     = "530976901147"
}

output "alb_alias" {
  description = "The Route53 record for the ALB"
  value       = aws_route53_record.alb_alias
}
