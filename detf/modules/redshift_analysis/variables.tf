variable "project" {
  type    = string
  default = "rsa" # Redshift Analysis
}

variable "vpc_cidr" { type = string }

variable "vpc_id" { type = string }

variable "public_subnets" { type = any }

##-------------------------------------------------------

# variable "aws_region" {
#   type    = string
#   default = "us-east-1"
# }

# variable "aws_profile" {
#   type        = string
#   default     = ""
#   description = "Optional AWS profile name for local dev"
# }


# variable "azs" {
#   type    = list(string)
#   default = ["us-east-1a", "us-east-1b"]
# }

variable "redshift_node_type" {
  type = string
  # cost-friendly for demo; change to ra3.4xlarge etc for production
  default = "ra3.xlplus" # Options: dc2.large, ds2.xlarge, ra3.xlplus
}

variable "redshift_cluster_identifier" {
  type    = string
  default = "rsa-cluster"
}

variable "redshift_db_name" {
  type    = string
  default = "dev"
}

variable "redshift_master_username" {
  type = string
}

variable "redshift_master_password" {
  type      = string
  sensitive = true
}

variable "node_count" {
  type    = number
  default = 1
}
