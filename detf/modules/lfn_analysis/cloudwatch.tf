## ================================================================
# Define an AWS CloudWatch Events rule
## ================================================================

resource "aws_cloudwatch_event_rule" "cw_event_rules" {
  for_each    = var.cw_events
  name        = each.key
  description = "Triggers the gpc_cuckoo Lambda function"

  schedule_expression = each.value

  tags = {
    Project = "${var.project}-scheduler"
  }
}


# ## =======================================================================
# # Define an AWS CloudWatch Events target to invoke the Lambda function
# ## =======================================================================

resource "aws_cloudwatch_event_target" "cw_event_targets" {
  for_each = aws_cloudwatch_event_rule.cw_event_rules

  rule = each.value.name
  arn  = aws_lambda_function.gpc_cuckoo.arn

  input = jsonencode({
    resources = [each.key]
  })
}



resource "aws_cloudwatch_log_group" "gpc_cuckoo_lg" {
  name              = "/aws/lambda/${aws_lambda_function.gpc_cuckoo.function_name}" # Specify the name of the log group
  retention_in_days = 7                                                             # Optional: Specify the retention period for log events in days

  tags = {
    Project = "${var.project}-gpc-cuckoo"
  }
}


resource "aws_cloudwatch_log_group" "sqs_processing_lg" {
  name              = "/aws/lambda/${aws_lambda_function.sqs_processor.function_name}" # Specify the name of the log group
  retention_in_days = 7                                                                # Optional: Specify the retention period for log events in days

  tags = {
    Project = "${var.project}-sqs-processor"
  }
}
