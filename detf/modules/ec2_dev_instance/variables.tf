variable "project" {
  type    = string
  default = "dev-ec2-instance"
}

variable "key_name" {
  type    = string
  default = "general_purpose"
}

variable "vpc_id" {
  type = any
}

variable "subnet_id" {
  type = string
}
