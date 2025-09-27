variable "projects" {
  type    = string
  default = "glue-workflow"
}

variable "vpc_id" {
  type = string
}

variable "subnets" {
  type = map(string)
}

variable "datalake_bkt" {
  type = any
}

variable "glue_assets_bkt" {
  type = any
}

variable "glue_temp_bkt" {
  type = any
}

variable "GLUE_ROLE_NAME" {
  type    = string
  default = "glue-pipeline-role"
}

variable "glue_catalog_databases" {
  type = any
}

variable "CUSTOMER_DQ_EVAL_JOB_NAME" {
  type    = string
  default = "customer-dq-eval"
}

