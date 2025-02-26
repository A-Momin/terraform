resource "aws_s3_bucket" "cuckoo_bkt" {
  bucket = "gpc-cuckoo-bucket"
  force_destroy = true

  tags = {
    Name        = "gpc-cuckoo-bucket"
    Environment = "Dev"
  }
}

resource "null_resource" "templates_transfer" {

  provisioner "local-exec" {
    command = "aws s3 cp ./templates s3://gpc-cuckoo-bucket --recursive"
  }
  depends_on = [aws_s3_bucket.cuckoo_bkt]
}


## ================================================================
# Define Lambda function
## ================================================================

resource "aws_lambda_function" "gpc_cuckoo" {
  function_name = "gpc_cuckoo"
  runtime       = "python3.9"
  role          = aws_iam_role.gpc_cuckoo_role.arn
  handler       = "cuckoo.handler"
  filename      = data.archive_file.lambda_zip.output_path
  # source_code_hash = data.archive_file.lambda.output_base64sha256
  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)
  timeout = 60  # Set the timeout here (in seconds)
  

  environment {
    variables = {
    #   LOG_GROUP_NAME = aws_cloudwatch_log_group.gpc_cuckoo_lg.name
      foo = "BAR"
    }
  }
}

resource "aws_cloudwatch_log_group" "gpc_cuckoo_lg" {
  name              = "/aws/lambda/gpc_cuckoo"  # Specify the name of the log group
  retention_in_days = 7  # Optional: Specify the retention period for log events in days
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir = "${path.module}/setup"               # `path.module` -> The path of the module where the expression is placed
  output_path = "${path.module}/python_cuckoo.zip"
  depends_on = [ null_resource.prepare_directory ]
}

resource "null_resource" "prepare_directory" {

  provisioner "local-exec" {
    command = "${path.module}/python/zipup_lambda.sh"
  }
}


## ================================================================
# Define an AWS CloudWatch Events rule
## ================================================================

resource "aws_cloudwatch_event_rule" "come_to_work" {
  name                = "come_to_work"
  schedule_expression = "cron(0 12 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_rule" "daily_tasks" {
  name                = "daily_tasks"
  schedule_expression = "cron(0 17 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_rule" "pickup" {
  name                = "pickup"
  schedule_expression = "cron(0 22 ? * MON-FRI *)"
}


## ================================================================
# Define an AWS CloudWatch Events target to invoke the Lambda function
## ================================================================

resource "aws_cloudwatch_event_target" "come_to_work" {
  rule = aws_cloudwatch_event_rule.come_to_work.name
  arn  = aws_lambda_function.gpc_cuckoo.arn
}

resource "aws_cloudwatch_event_target" "daily_tasks" {
  rule = aws_cloudwatch_event_rule.daily_tasks.name
  arn  = aws_lambda_function.gpc_cuckoo.arn
}

resource "aws_cloudwatch_event_target" "pickup" {
  rule = aws_cloudwatch_event_rule.pickup.name
  arn  = aws_lambda_function.gpc_cuckoo.arn
}


## ================================================================
# Add permissions to CloudWatch Events rules to invoke Lambda function
## ================================================================
resource "aws_lambda_permission" "come_to_work" {
  statement_id  = "1"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.gpc_cuckoo.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.come_to_work.arn
}

resource "aws_lambda_permission" "daily_tasks" {
  statement_id  = "2"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.gpc_cuckoo.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_tasks.arn
}

resource "aws_lambda_permission" "pickup" {
  statement_id  = "3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.gpc_cuckoo.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.pickup.arn
}
