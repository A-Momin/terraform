resource "aws_glue_crawler" "s3_customer_crawler" {
  name          = var.S3_CUSTOMER_CRAWLER_NAME
  database_name = var.glue_catalog_databases["gcdb-bronze"].name
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path = "s3://${var.datalake_bkt.bucket}/bronze/customers/"
  }

  table_prefix = "bronze_" # (Optional) The table prefix used for catalog tables that are created.
  #   recrawl_policy = "" # (Optional) A policy that specifies whether to crawl the entire dataset again, or to crawl only folders that were added since the last crawler run.
  #   schedule = "" # (Optional) A cron expression used to specify the schedule. For more information,

  tags = {
    "Project" = "${var.PROJECT}-crawler"
  }

  depends_on = [aws_iam_role.glue_role]
}

resource "aws_glue_job" "customer_processing_job" {
  name              = var.CUSTOMER_PROCESSING_JOB_NAME
  role_arn          = aws_iam_role.glue_role.arn
  glue_version      = "4.0"
  number_of_workers = 2
  worker_type       = "G.1X" # Standard' | 'G.1X' | 'G.2X'
  max_retries       = 0
  timeout           = 10

  command {
    name            = "glueetl"
    script_location = "s3://${var.glue_assets_bkt.bucket}/glue_scripts/customer_processing_job.py"
    python_version  = "3"
  }

  default_arguments = {
    "--TempDir"                          = "s3://${var.glue_assets_bkt.bucket}/temporary",
    "--library-path"                     = "s3://${var.glue_assets_bkt.bucket}/libraries",             # Path to external libraries (JARs, compiled libraries, JDBC drivers)
    "--extra-py-files"                   = "s3://${var.glue_assets_bkt.bucket}/libraries/package.zip", # Python modules/packages (Python .zip)
    "--spark-event-logs-path"            = "s3://${var.glue_assets_bkt.bucket}/sparkHistoryLogs/",
    "--job-bookmark-option"              = "job-bookmark-enable",
    "--job-language"                     = "python",
    "--enable-continuous-cloudwatch-log" = "true"
    # "--continuous-log-group"             = aws_cloudwatch_log_group.glue_continuous_log_group.name # Continuous logging is often enabled alongside metrics
    "--enable-metrics" = "true" # AWS Glue can also publish detailed metrics about your job's performance to CloudWatch. These metrics are published to a separate log group.
    # "--enable-metrics"                   = ""
    # "--enable-spark-ui"                  = ""
  }

  tags = {
    "Project" = "${var.PROJECT}-job"
  }

  depends_on = [aws_iam_role.glue_role]
}
