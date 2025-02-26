terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Terraform will fetch information about the AWS caller identity (such as AWS account ID, ARN, etc.) and store it in the Terraform state.
data "aws_caller_identity" "current" {}

