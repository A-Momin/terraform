resource "aws_cloudwatch_event_rule" "customar_crawler_status_rule" {
  name        = var.S3_CUSTOMER_CRAWLER_RULE_NAME
  description = "Triggers when the customer crawler completes"
  event_pattern = jsonencode({
    source      = ["aws.glue", "my-custom-source"]
    detail-type = ["Glue Crawler State Change"],
    detail = {
      state       = ["Succeeded"]
      crawlerName = [var.S3_CUSTOMER_CRAWLER_NAME]
    }
  })

  tags = {
    Project = "glue-event-based-pipeline"
  }
}

resource "aws_cloudwatch_event_target" "trigger_customer_processing_lfn" {
  rule = aws_cloudwatch_event_rule.customar_crawler_status_rule.name
  arn  = aws_lambda_function.glue_job_starter.arn
  input = jsonencode({
    "--JOB_NAME"           = var.CUSTOMER_PROCESSING_JOB_NAME
    "--S3_BUCKET_DATALAKE" = var.datalake_bkt.bucket
    "--CATALOG_DB_NAME"    = var.glue_catalog_databases["gcdb-bronze"].name
    "--TABLE_NAME"         = "${local.bronze}_customers"
    "--TARGET"             = "s3://${var.datalake_bkt.bucket}/silver/customers/"
  })
}

resource "aws_cloudwatch_event_rule" "customer_processing_job_status_rule" {
  name        = var.S3_CUSTOMER_PROCESSING_JOB_RULE_NAME
  description = "Triggers when the customer processing job completes to send notification"
  event_pattern = jsonencode({
    source      = ["aws.glue"]
    detail-type = ["Glue Job State Change"],
    detail = {
      state   = ["SUCCEEDED", "FAILED", "TIMEOUT"]
      jobName = [var.CUSTOMER_PROCESSING_JOB_NAME]
    }
  })
}

resource "aws_cloudwatch_event_target" "notify_sns_topic" {
  rule = aws_cloudwatch_event_rule.customer_processing_job_status_rule.name
  arn  = aws_sns_topic.glue_sns_topic.arn
}

resource "aws_cloudwatch_log_group" "s3_customer_crawler_triggerer_lg" {
  name              = "/aws/lambda/${aws_lambda_function.s3_customer_crawler_triggerer.function_name}"
  retention_in_days = 1

  tags = {
    Project = "glue-event-based-pipeline"
  }
}

resource "aws_cloudwatch_log_group" "glue_job_starter_lg" {
  name              = "/aws/lambda/${aws_lambda_function.glue_job_starter.function_name}"
  retention_in_days = 1

  tags = {
    Project = "glue-event-based-pipeline"
  }
}

resource "aws_cloudwatch_log_group" "glue_continuous_log_group" {
  name              = "/aws-glue/jobs/continuous"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "glue_metrics_log_group" {
  name              = "/aws-glue/jobs/metrics"
  retention_in_days = 30
}
