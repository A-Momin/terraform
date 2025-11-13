variable "project" {
  type    = string
  default = "EC2-DEV-ENVIRONMENT"
}

variable "key_name" {
  type    = string
  default = "general_purpose"
}

variable "vpc_id" {
  type = any

  default = "default"
}

variable "subnet_id" {
  type    = string
  default = "default"
}

variable "script_type" {
  type    = string
  default = "amazon-linux"
}

variable "ec2_username" {
  type    = string
  default = "ec2-user"
}

variable "ami_id" {
  type    = string
  default = "ami-0ecb62995f68bb549"
}

variable "bash_config_scripts_location" {
  type    = string
  default = "/Users/am/mydocs/Software_Development/noteshub/dotfiles/lnx"
}
