#######################
# Glue Jobs
#######################
resource "aws_glue_job" "job1" {
  name              = "${var.prefix}-glue-job-01"
  role_arn          = aws_iam_role.glue_service_role.arn
  max_retries       = 0
  glue_version      = "4.0"
  number_of_workers = 2
  worker_type       = "G.1X" # Standard' | 'G.1X' | 'G.2X'
  command {
    name            = "glueetl"
    python_version  = "3"
    script_location = "s3://${var.glue_assets_bkt.bucket}/glue_scripts/job1_etl.py"
  }

  default_arguments = {
    "--TempDir"                          = "s3://${var.glue_assets_bkt.bucket}/temporary",
    "--library-path"                     = "s3://${var.glue_assets_bkt.bucket}/libraries",             # Path to external libraries (JARs, compiled libraries, JDBC drivers)
    "--extra-py-files"                   = "s3://${var.glue_assets_bkt.bucket}/libraries/package.zip", # Python modules/packages (Python .zip)
    "--spark-event-logs-path"            = "s3://${var.glue_assets_bkt.bucket}/sparkHistoryLogs/",
    "--job-bookmark-option"              = "job-bookmark-enable",
    "--job-language"                     = "python",
    "--enable-continuous-cloudwatch-log" = "true",
    # "--continuous-log-group"             = aws_cloudwatch_log_group.glue_continuous_log_group.name # Continuous logging is often enabled alongside metrics
    "--enable-metrics" = "true", # AWS Glue can also publish detailed metrics about your job's performance to CloudWatch. These metrics are published to a separate log group.
    # "--enable-metrics"                   = ""
    # "--enable-spark-ui"                  = ""

    "--DATALAKE_BKT" = var.datalake_bkt.bucket
    "--INPUT_KEY"    = "bronze/sales/sales_tiny.csv"
    "--OUTPUT_KEY"   = "silver/sales/processed_sales_tiny.csv"

    # When a Glue Job runs as part of a workflow, AWS automatically injects the `WORKFLOW_RUN_ID` and `WORKFLOW_NAME` as special system arguments (prefixed with --) which you must define in the default_arguments map, even though the value {context.workflow_run_id} is a placeholder that will be replaced at runtime.
    "--WORKFLOW_RUN_ID" = "{context.workflow_run_id}"
    "--WORKFLOW_NAME"   = "{context.workflow_name}"
  }

}

resource "aws_glue_job" "job2" {
  name     = "${var.prefix}-glue-job-02"
  role_arn = aws_iam_role.glue_service_role.arn

  command {
    name            = "glueetl"
    python_version  = "3"
    script_location = "s3://${var.glue_assets_bkt.bucket}/glue_scripts/job2_etl.py"
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

    "--DATALAKE_BKT" = var.datalake_bkt.bucket
    "--OUTPUT_KEY"   = "gold/sales/curated_sales_tiny.csv"


    # When a Glue Job runs as part of a workflow, AWS automatically injects the `WORKFLOW_RUN_ID` and `WORKFLOW_NAME` as special system arguments (prefixed with --) which you must define in the default_arguments map, even though the value {context.workflow_run_id} is a placeholder that will be replaced at runtime.
    "--WORKFLOW_RUN_ID" = "{context.workflow_run_id}"
    "--WORKFLOW_NAME"   = "{context.workflow_name}"
  }

  max_retries       = 0
  glue_version      = "4.0"
  number_of_workers = 2
  worker_type       = "G.1X" # Standard' | 'G.1X' | 'G.2X'
}

resource "aws_s3_object" "upload_glue_job_script" {

  for_each = fileset("${path.module}/glue_scripts", "**")

  bucket = var.glue_assets_bkt.bucket
  key    = "/glue_scripts/${each.value}" # prefix in bucket
  source = "${path.module}/glue_scripts/${each.value}"
  etag   = filemd5("${path.module}/glue_scripts/${each.value}")
}


#######################
# Glue Workflow
#######################
resource "aws_glue_workflow" "glue_workflow" {
  name        = "${var.prefix}-glue-workflow"
  description = "Demo workflow with two jobs chained via triggers"
}

#######################
# Glue Triggers: job1 runs when workflow starts; job2 runs when job1 succeeds
#######################
# Trigger: ON_DEMAND (will be invoked by workflow start)
resource "aws_glue_trigger" "trigger_job1" {
  name = "${var.prefix}-trigger-job1"
  type = "ON_DEMAND"

  actions {
    job_name = aws_glue_job.job1.name
  }

  workflow_name = aws_glue_workflow.glue_workflow.name
}

# Trigger: CONDITIONAL, starts job2 when job1 SUCCESS
resource "aws_glue_trigger" "trigger_after_job1" {
  name = "${var.prefix}-trigger-job2"
  type = "CONDITIONAL"

  actions {
    job_name = aws_glue_job.job2.name
  }

  predicate {
    conditions {
      logical_operator = "EQUALS"
      job_name         = aws_glue_job.job1.name
      state            = "SUCCEEDED"
    }
  }

  workflow_name = aws_glue_workflow.glue_workflow.name
}

