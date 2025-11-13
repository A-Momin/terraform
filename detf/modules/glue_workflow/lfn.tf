#######################
# Lambda: start workflow on S3 put (EventBridge rule)
#######################
resource "aws_lambda_function" "start_glue_workflow" {
  function_name = "${var.prefix}-start-glue-workflow"
  s3_bucket     = var.glue_assets_bkt.bucket
  s3_key        = "lfn_deployment_pkg/start_glue_workflow_lambda.zip"
  handler       = "start_glue_workflow_lambda.lambda_handler"
  runtime       = "python3.11"
  role          = aws_iam_role.lambda_role.arn
  timeout       = 120 # Default is 3 seconds, can be set up to 900 seconds (15 minutes)
  memory_size   = 128 # Default is 128 MB, can be set between 128 MB and 10,240 MB
  layers        = [var.lfn_layer_arn]


  #   reserved_concurrent_executions = 9 # Reserved Concurrency (max limit)

  # Whether to publish creation/change as new Lambda Function Version.
  publish       = false      # Default is false
  architectures = ["x86_64"] # Default is "x86_64", other option is "arm64"


  environment {
    variables = {
      GLUE_WORKFLOW_NAME = aws_glue_workflow.glue_workflow.name
      # DATALAKE_BKT      = var.datalake_bkt.bucket
    }
  }

  depends_on = [aws_s3_object.lambda_deployment_pkg]
}

data "archive_file" "zip_up_lambda" {
  type        = "zip"
  source_file = "${path.module}/lfn/start_glue_workflow_lambda.py"
  output_path = "${path.module}/lfn/start_glue_workflow_lambda.zip"
}

# Upload Lambda code zip (assumes you build lambda.zip into ../lambda/lambda.zip)
resource "aws_s3_object" "lambda_deployment_pkg" {
  bucket = var.glue_assets_bkt.bucket
  key    = "lfn_deployment_pkg/start_glue_workflow_lambda.zip"
  source = data.archive_file.zip_up_lambda.output_path
  etag   = filemd5(data.archive_file.zip_up_lambda.output_path)

  depends_on = [data.archive_file.zip_up_lambda]
}

# EventBridge rule to capture s3:Object Created and trigger Lambda (pattern uses s3 Put events via aws:s3)
resource "aws_cloudwatch_event_rule" "s3_put_rule" {
  name        = "${var.prefix}-s3-put-rule"
  description = "Triggered when an object is created in the specified S3 bucket."

  event_pattern = jsonencode({ # This 'detail' is sent to Lambda in the 'event' payload along with other metadata.
    source      = ["aws.s3", "my-custom-source"],
    detail-type = ["Object Created"],
    detail = {
      object = {
        key = [{ "prefix" = "bronze/sales/" }]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "rule_target_lambda" {
  target_id = "invoke-lambda"
  rule      = aws_cloudwatch_event_rule.s3_put_rule.name
  arn       = aws_lambda_function.start_glue_workflow.arn
  input = jsonencode({
    GLUE_WORKFLOW_NAME = aws_glue_workflow.glue_workflow.name,
    # "--DATALAKE_BKT"   = "${var.datalake_bkt.bucket}",
    # "--BKT_KEY"        = "bronze/sales/"
  })
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_glue_workflow.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_put_rule.arn
}
