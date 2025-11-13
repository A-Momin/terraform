resource "aws_lambda_function" "s3_customer_crawler_triggerer" {
  function_name    = var.CUSTOMER_CRAWLER_LFN_NAME
  role             = aws_iam_role.lfn_role.arn
  handler          = "crawler_triggerer.crawler_trigger_handler" # file_name.function_name
  runtime          = "python3.9"
  timeout          = 120 # Set the timeout here (in seconds)
  filename         = data.archive_file.zip_up_lambda.output_path
  source_code_hash = data.archive_file.zip_up_lambda.output_base64sha256

  environment {
    variables = {
      S3_CUSTOMER_CRAWLER_NAME = aws_glue_crawler.s3_customer_crawler.name
    }
  }

  tags = {
    "Project" = "glue-event-based-pipeline"
  }

  depends_on = [aws_iam_role.lfn_role, aws_glue_crawler.s3_customer_crawler]
}

resource "aws_lambda_permission" "allow_s3_to_invoke_lambda" {
  statement_id  = "${aws_lambda_function.s3_customer_crawler_triggerer.function_name}-permission"
  function_name = aws_lambda_function.s3_customer_crawler_triggerer.function_name
  source_arn    = var.datalake_bkt.arn
  principal     = "s3.amazonaws.com"
  action        = "lambda:InvokeFunction"
  depends_on    = [aws_lambda_function.s3_customer_crawler_triggerer]
}

resource "aws_lambda_function" "glue_job_starter" {
  function_name    = var.CUSTOMER_JOB_STARTER_LFN_NAME
  role             = aws_iam_role.lfn_role.arn
  handler          = "glue_job_starter.job_starter_handler" # file_name.function_name
  runtime          = "python3.9"
  timeout          = 120 # Set the timeout here (in seconds)
  filename         = data.archive_file.zip_up_lambda.output_path
  source_code_hash = data.archive_file.zip_up_lambda.output_base64sha256

  environment {
    variables = {
      GLUE_JOB_NAME = aws_glue_job.customer_processing_job.name
    }
  }

  tags = {
    "Project" = "glue-event-based-pipeline"
  }

  depends_on = [aws_iam_role.lfn_role, aws_glue_job.customer_processing_job]
}

resource "aws_lambda_permission" "allow_eventbridge_to_invoke_lambda" {
  function_name = aws_lambda_function.glue_job_starter.function_name
  statement_id  = "${aws_lambda_function.glue_job_starter.function_name}-permission"
  source_arn    = aws_cloudwatch_event_rule.customar_crawler_status_rule.arn
  principal     = "events.amazonaws.com"
  action        = "lambda:InvokeFunction"
  depends_on    = [aws_lambda_function.glue_job_starter]
}

