variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "my-first-kafka-project"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "The VPC object"
  type        = string
  default     = "vpc-043506b8f2a3086b7"
}

variable "vpc_cidr_block" {
  description = "The VPC object"
  type        = string
  default     = "20.20.0.0/16"
}

variable "public_subnets" {
  description = "Map of public subnet IDs"
  type        = set(string)
  default     = ["subnet-0923d23cbcc79dc9c", "subnet-07910447c7be16a94"]
}

variable "private_subnets" {
  description = "Map of private subnet IDs"
  type        = set(string)
  default     = ["subnet-080856a486501be0f", "subnet-0760170ed6f75b8eb"]

  #   # If you only need a few fields (e.g., `id` and `availability_zone`), you can define a smaller object:
  #   type = map(object({
  #     id                = string
  #     availability_zone = string
  #   }))
}
