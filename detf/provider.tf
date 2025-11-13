terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0" # greater than or equal to 5.0 and less than 6.0.
    }
  }

  #############################################################################
  ########## HOW TO SWITCH FROM LOCAL BACKEND TO REMOTE AWS BACKEND:###########
  #############################################################################
  ## INITIALIZE TERRAFORM WITH LOCAL BACKEND AT THE BEGINNING.
  ## THEN PROVISION RESOURCES DEFINED ON `backend_config_resources.tf` BY 
  ## UNCOMMENTING THE CODE  ON THAT SCRIPT AND THEN RUNNING `terraform apply`.
  #############################################################################
  ## AFTER PROVISIONING RESOURCES DEFINED ON `backend_config_resources.tf`,
  ## YOU WILL UNCOMMENT THE FOLLOWING `backend` BLOCK THEN RERUN `terraform init`
  ## TO SWITCH FROM LOCAL BACKEND TO REMOTE AWS BACKEND
  ## NOTE: YOU CANNOT USE VARIABLES OR REFERENCES IN THE `BACKEND` BLOCK.
  #############################################################################

  #   backend "s3" {
  #     bucket         = "tf-state-bkt-htech" # reference/variable is not allowed
  #     key            = "terraform.tfstate"
  #     region         = "us-east-1"
  #     dynamodb_table = "tf-state-locking-ddb-tbl" # reference/variable is not allowed
  #     encrypt        = true
  #   }

}

# provider "aws" {
#   alias  = "replica"
#   region = "us-east-1"
# }
