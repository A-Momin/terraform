variable "project" {
  type    = string
  default = "DETF"
}

variable "VPC_CIDR" {
  type    = string
  default = "20.20.0.0/16"
}

variable "PUBLIC_SUBNETS" {
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))

  default = {
    public_subnet_1 = { cidr_block = "20.20.0.0/24", availability_zone = "us-east-1a" }
    public_subnet_2 = { cidr_block = "20.20.32.0/24", availability_zone = "us-east-1b" }
  }
}

variable "PRIVATE_SUBNETS" {
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))

  default = {
    private_subnet_1 = { cidr_block = "20.20.64.0/24", availability_zone = "us-east-1a" }
    private_subnet_2 = { cidr_block = "20.20.96.0/24", availability_zone = "us-east-1b" }
  }
}

variable "BUCKETS" {
  type    = list(string)
  default = ["datalake-bkt-10102025", "glue-assets-bkt-10102025", "glue-temp-bkt-10102025"]
}

variable "GLUE_CATALOG_DB_NAMES" {
  type    = list(string)
  default = ["gcdb-bronze", "gcdb-silver"] # Glue Catalog DataBase
}

variable "redshift_master_username" {
  type = string
}

variable "redshift_master_password" {
  type      = string
  sensitive = true
}

# ----------------------------
# 1. Define variables
# ----------------------------
variable "iam_users" {
  default = [
    "Clinton",
    "Joe",
    "Trump"
  ]
}

variable "iam_groups" {
  default = [
    "admins",
    "developers",
  ]
}
