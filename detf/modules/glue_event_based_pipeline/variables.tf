variable "PROJECT" {
  type    = string
  default = "glue-event-based-pipeline"
}

variable "LFN_ROLE_NAME" {
  type    = string
  default = "lfn-pipeline-role"
}

variable "GLUE_ROLE_NAME" {
  type    = string
  default = "glue-pipeline-role"
}


variable "glue_catalog_databases" {
  type = any
}

variable "TOPIC_NAME" {
  type    = string
  default = "glue-event-based-pipeline-topic"
}

variable "CUSTOMER_CRAWLER_LFN_NAME" {
  type    = string
  default = "s3-customer-crawler-triggerer"
}

variable "CUSTOMER_JOB_STARTER_LFN_NAME" {
  type    = string
  default = "s3-customer-processing-job-starter"
}

variable "S3_CUSTOMER_CRAWLER_NAME" {
  type    = string
  default = "s3-customer-crawler"
}

variable "CUSTOMER_PROCESSING_JOB_NAME" {
  type    = string
  default = "s3-customer-processing-job"
}

variable "S3_CUSTOMER_CRAWLER_RULE_NAME" {
  type    = string
  default = "s3-customer-crawler-rule"
}

variable "S3_CUSTOMER_PROCESSING_JOB_RULE_NAME" {
  type    = string
  default = "s3-customer-processing-job-rule"
}

variable "CUSTOMER_DQ_EVAL_JOB_NAME" {
  type    = string
  default = "customer-dq-eval"
}

# S3_SALES_CRAWLER
# S3_SALES_CRAWLER_TARGET
# LFN_JOB_TRIGGERER_NAME


variable "LFN_ROLE_AWSM_POLICY" {
  type = list(string)
  default = [
    "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole",
    "arn:aws:iam::aws:policy/CloudWatchFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AdministratorAccess",
    "arn:aws:iam::aws:policy/PowerUserAccess"
  ]
}

variable "lftn_admin_user" {
  type = any
}

variable "SNS_EMAIL_ENDPOINT" {
  type    = string
  default = "AMominNJ@gmail.com"
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

variable "run_prepare_glue_external_py_lib" {
  type    = bool
  default = false
}
