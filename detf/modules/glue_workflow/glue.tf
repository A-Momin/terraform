# in progress (not yet tested)
resource "aws_glue_data_quality_ruleset" "customer_dq_eval_ruleset" {
  name        = "customer-data-quality-ruleset"
  description = "Data quality ruleset for customer data"

  target_table {
    database_name = aws_glue_catalog_database.glue_catalog_db.name
    table_name    = "customers"
  }

  ruleset = <<EOT
    Rules = [
    ColumnExists "CUSTOMERID",
    ColumnExists "CUSTOMERNAME",
    ColumnExists "EMAIL",
    IsComplete "CUSTOMERID",
    IsUnique "CUSTOMERID",
    IsComplete "EMAIL"
    ]
  EOT
  tags = {
    "Project" = "glue-workflow"
  }
}

resource "aws_glue_job" "customer_dq_eval_job" {
  name              = var.CUSTOMER_DQ_EVAL_JOB_NAME
  role_arn          = aws_iam_role.glue_role.arn
  max_retries       = 0
  glue_version      = "5.0"
  number_of_workers = 2
  worker_type       = "G.1X"
  #   timeout           = 5 # in 

  command {
    name            = "glueetl"
    script_location = "s3://${var.glue_assets_bkt.bucket}/glue_scripts/customer_dq_eval.py"
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
    #----------------------------------------------------------------------
    # Data Quality Evaluation Job Specific Arguments
    #----------------------------------------------------------------------
    # "--JOB_NAME"                = "${var.CUSTOMER_DQ_EVAL_JOB_NAME}"
    # "--CATALOG_DB_NAME"         = "${aws_glue_catalog_database.glue_catalog_db.name}"
    # "--TABLE_NAME"              = "customers"
    # "--data_quality_ruleset_id" = aws_glue_data_quality_ruleset.customer_dq_eval_ruleset.id
    # "--dq_results_path" = "s3://${var.datalake_bkt.bucket}/DQE-Results/customers/"

  }

  tags = {
    "Project" = "glue-workflow"
  }
}

# resource "aws_glue_trigger" "customer_dq_eval_job_trigger" {
#   name = "dq-eval-customer-job-trigger"
#   type = "CONDITIONAL"

#   actions {
#     job_name = aws_glue_job.customer_dq_eval_job.name
#   }

#   predicate {
#     conditions {
#       crawler_name = aws_glue_crawler.s3_customer_crawler.name
#       crawl_state  = "SUCCEEDED"
#     }
#   }

#   tags = {
#     "Project" = "glue-workflow"
#   }
# }

# resource "aws_glue_crawler" "customer_dq_eval_crawler" {
#   name          = "customer-dq-eval-crawler"
#   role          = aws_iam_role.glue_role.arn
#   database_name = aws_glue_catalog_database.glue_catalog_db.name

#   s3_target {
#     path = "s3://${var.datalake_bkt.bucket}/DQ-Evaluations/customers_dqe/"
#   }

#   #   recrawl_policy = "" # (Optional) A policy that specifies whether to crawl the entire dataset again, or to crawl only folders that were added since the last crawler run.
#   #   table_prefix = "" # (Optional) The table prefix used for catalog tables that are created.
#   #   schedule = "cron(0 12 * * ? *)" # optional: run daily

#   tags = {
#     "Project" = "glue-workflow"
#   }

# }

# resource "aws_glue_trigger" "customer_dq_eval_crawler_trigger" {

#   name = "customer-dq-eval-crawler-trigger"
#   type = "CONDITIONAL"

#   actions {
#     crawler_name = aws_glue_crawler.customer_dq_eval_crawler.name
#   }

#   predicate {
#     conditions {
#       job_name = aws_glue_job.customer_dq_eval_job.name
#       state    = "SUCCEEDED"
#     }
#   }

#   tags = {
#     "Project" = "glue-workflow"
#   }
# }
