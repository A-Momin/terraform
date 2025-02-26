terraform {
  required_version = "0.11.8"

  backend "s3" {
    bucket  = ""
    key     = ""
    profile = ""
    region  = ""
  }
}

provider "aws" {
  profile                 = "${var.aws_profile}"
  region                  = "${var.aws_region}"
#   shared_credentials_file = "${var.aws_credentials_file}"
#   version                 = "1.37.0"
}

# Terraform will fetch information about the AWS caller identity (such as AWS account ID, ARN, etc.) and store it in the Terraform state.
data "aws_caller_identity" "current" {}
